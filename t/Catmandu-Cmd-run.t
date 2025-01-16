#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::run';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [qw(run t/run.fix)]);

my $perl = decode_json($result->stdout);

ok $perl, 'got JSON';
is $perl->{hello}, 'world', 'got data';
is $result->error, undef,   'threw no exceptions';

# Next test can fail on buggy Perl installations
##is $result->stderr, '', 'nothing sent to sderr' ;

done_testing 5;
