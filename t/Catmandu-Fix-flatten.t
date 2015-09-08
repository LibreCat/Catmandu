#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::flatten';
    use_ok $pkg;
}

is_deeply
    $pkg->new('deep')->fix({deep => [1,[2,3],[[4,5],6],7]}),
    {deep => [1 .. 7]};

done_testing;
