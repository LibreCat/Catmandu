#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::sort_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('tags')->fix({tags => ["foo", "bar","bar"] }),
    {tags => ["bar","bar","foo"] },
    "sort alphanum";

is_deeply
    $pkg->new('tags',uniq=>1)->fix({tags => ["foo", "bar","bar"] }),
    {tags => ["bar","foo"] },
    "sort unique";

is_deeply
    $pkg->new('tags',uniq=>1,reverse=>1)->fix({tags => ["foo", "bar","bar"] }),
    {tags => ["foo","bar"] },
    "sort unique reverse";

is_deeply
    $pkg->new('nums',numeric=>1)->fix({ nums => [ 100, 1 , 10] }),
    {nums => [ 1, 10, 100]},
    "sort numeric";

done_testing 5;
