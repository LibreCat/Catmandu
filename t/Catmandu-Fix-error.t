#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::error';
    use_ok $pkg;
}

throws_ok {$pkg->new('!!!ERROR!!!')->fix({})} qr/!!!ERROR!!!/,
    'dies with an error message';

done_testing;
