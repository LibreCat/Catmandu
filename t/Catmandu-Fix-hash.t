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
    $pkg->new('tags')->fix({tags => ["name", "Peter","age",12] }),
    {tags => { name => 'Peter' , age => 12} },
    "hashing the array";

is_deeply
    $pkg->new('tags',-invert=>1)->fix({tags => { name => 'Peter'} }),
    {tags => [ 'name' , 'Peter' ] },
    "hashing the array (invert)";

done_testing 2;