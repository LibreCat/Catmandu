#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::uniq';
    use_ok $pkg;
}

is_deeply $pkg->new('array')->fix({ array => ["a","a","b","c","d","D"]}),{array => ["a","b","c","d","D"]},"string values";
is_deeply $pkg->new('array')->fix({ array => [undef,undef]}),{array => [undef]},"undefined values";
is_deeply $pkg->new('array')->fix({ array => ["a",undef,undef,"b","b","c"]}),{array => ["a",undef,"b","c"]},"undefined and string values";

done_testing 4;
