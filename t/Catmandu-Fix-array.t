#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::array';
    use_ok $pkg;
} 

is_deeply
    $pkg->new('tags')->fix({tags => {name => 'Peter'}}),
    {tags => ['name', 'Peter']},
    "hash to array";

done_testing 2;

