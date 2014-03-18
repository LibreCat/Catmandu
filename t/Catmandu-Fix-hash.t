#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::hash';
    use_ok $pkg;
} 

is_deeply
    $pkg->new('tags')->fix({tags => ["name", "Peter", "age", 13]}),
    {tags => {name => 'Peter', age => 13}},
    "array to hash";

done_testing 2;

