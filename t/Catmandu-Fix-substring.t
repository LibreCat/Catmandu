#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::substring';
    use_ok $pkg;
}

is_deeply
    $pkg->new('rel', 5, 3)->fix({rel => "grandson"}),
    {rel => "son"};

dies_ok { $pkg->new('rel', 9, 3)->fix({rel => "grandson"}) };

is_deeply
    $pkg->new('rel', 5, 3, 'daughter')->fix({rel => "grandson"}),
    {rel => "granddaughter"};

is_deeply
    $pkg->new('arr.*.rel', 5)->fix({arr => [{rel => "grandson"}, {rel => "granddaughter"}]}),
    {arr => [{rel => "son"}, {rel => "daughter"}]};

done_testing 5;
