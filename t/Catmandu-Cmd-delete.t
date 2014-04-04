#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::delete';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(delete test) ]);

is $result->stdout, "" , 'got data';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

done_testing 5;