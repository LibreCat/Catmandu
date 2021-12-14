#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::copy';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [qw(copy -v test to Hash)]);

like $result->stderr, qr/copied 4 items/, 'copied 4 items';
is $result->error, undef, 'threw no exceptions';

done_testing;
