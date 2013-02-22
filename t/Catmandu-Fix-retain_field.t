#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::retain_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('keep')->fix({remove => 'me', also => 'me', keep => 'me'}),
    {keep => 'me'};

is_deeply
    $pkg->new('unknown')->fix({remove => 'me', also => 'me'}),
    {};

done_testing 3;

