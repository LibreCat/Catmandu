#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use JSON;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::convert';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(convert YAML --file t/catmandu.yml to JSON) ]);

my $perl = from_json($result->stdout);

ok $perl, 'got JSON';
is $perl->{importer}->{default}->{package} , 'YAML' , 'got data';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

done_testing 6;