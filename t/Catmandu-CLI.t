#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::CLI';
    use_ok $pkg;
}
require_ok $pkg;

{
    package Catmandu::Fix::thisFixThrowsAnError;

    use Catmandu::Sane;
    use Moo;

    sub fix { Catmandu::FixError->throw("bad boy"); }
}

# check -I / --lib_path
if ($^O ne 'MSWin32') { # /dev/null required
    # TODO Catmandu dies if testing with output to STDOUT
    my $res;
    $res = test_app('Catmandu::CLI' => [qw(
        -I t/lib convert Values --values 1;2;8 to JSON --file /dev/null
    )]);
    ok !$res->error;
    is $res->stderr, "";

    $res = test_app('Catmandu::CLI' => [qw(
        -I t/lib convert Values --values 1;2;8 to NotFound --file /dev/null
    )]);
    ok !$res->error;
    like $res->stderr, qr/Oops! Can't find the exporter 'NotFound'/;
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(-D3 help) ]);
    like $result->stderr , qr/(debug activated|Log::Log4perl)/ , 'see some debug information';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert help) ]);
    like $result->stderr , qr/Did you mean 'catmandu help convert'/ , 'wrong order help command';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert Null to Null --fix testing123() )]);
    like $result->stderr , qr/Catmandu::Fix::testing123/ , 'wrong fix error';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert Null to Null --fix) , "test("]);
    like $result->stderr , qr/Syntax error/ , 'syntax error';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert Null to Null --fix thisFixThrowsAnError())]);
    like $result->stderr , qr/One of your fixes threw an error/ , 'fix error';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert Null to Null --fix add_field() )]);
    like $result->stderr , qr/wrong arguments/ , 'wrong arguments';
}

{
    my $result = test_app(qq|Catmandu::CLI| => [ qw(convert Null to Testing123 )]);
    like $result->stderr , qr/Catmandu::Exporter::Testing123/ , 'wrong exporter error';
}

done_testing;
