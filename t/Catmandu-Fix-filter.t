#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::filter';
    use_ok $pkg;
}

is_deeply
    $pkg->new('words', 'Pa')->fix({words => [qw(Patrick Nicolas Paul Frank)]}),
    {words => [qw(Patrick Paul)]};

is_deeply
    $pkg->new('words', 'Przewalski')->fix({words => [qw(Patrick Nicolas Paul Frank)]}),
    {words => [qw()]};

done_testing 3;
