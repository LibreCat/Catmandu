#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use JSON;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::export';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(export test to JSON) ]);

my @lines = split(/\n/,$result->stdout);
my $perl = from_json($lines[0]);

ok $perl, 'got JSON';
is $perl->{value} , 'Sol' , 'got data';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

done_testing 6;