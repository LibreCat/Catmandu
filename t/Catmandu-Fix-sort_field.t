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
    $pkg->new('tags')->fix({tags => [undef,undef,"b","b","c","a"]}),
    { tags => ["a","b","b","c",undef,undef]},
    "sort with undefined values";

is_deeply
    $pkg->new('tags',undef_position=>"last")->fix({tags => ["b",undef,undef,"b","c","a"]}),
    { tags => ["a","b","b","c",undef,undef]},
    "sort with undefined values, undef last";

is_deeply
    $pkg->new('tags',undef_position=>"first")->fix({tags => [undef,"b","b","c",undef,"a"]}),
    { tags => [undef,undef,"a","b","b","c"]},
    "sort with undefined values, undef first";

is_deeply
    $pkg->new('tags',undef_position=>"delete")->fix({tags => [undef,undef,"b","b","c","a"]}),
    { tags => ["a","b","b","c"]},
    "sort with undefined values, remove undef";

is_deeply
    $pkg->new('tags',uniq=>1)->fix({tags => [undef,undef,"b","b","c","a"]}),
    { tags => ["a","b","c",undef]},
    "sort uniq with undefined values";

is_deeply
    $pkg->new('tags',uniq=>1,undef_position=>"last")->fix({tags => ["b",undef,undef,"b","c","a"]}),
    { tags => ["a","b","c",undef]},
    "sort uniq with undefined values, undef last";

is_deeply
    $pkg->new('tags',uniq=>1,undef_position=>"first")->fix({tags => [undef,"b","b","c",undef,"a"]}),
    { tags => [undef,"a","b","c"]},
    "sort uniq with undefined values, undef first";

is_deeply
    $pkg->new('tags',uniq=>1,undef_position=>"delete")->fix({tags => [undef,undef,"b","b","c","a"]}),
    { tags => ["a","b","c"]},
    "sort uniq with undefined values, remove undef";

is_deeply
    $pkg->new('tags',uniq=>1,reverse=>1)->fix({tags => ["foo", "bar","bar"] }),
    {tags => ["foo","bar"] },
    "sort unique reverse";

is_deeply
    $pkg->new('nums',numeric=>1)->fix({ nums => [ 100, 1 , 10] }),
    {nums => [ 1, 10, 100]},
    "sort numeric";

done_testing 13;
