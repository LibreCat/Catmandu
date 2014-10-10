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

is_deeply $pkg->new('array')->fix({ array => ["a","a","b","c","d","D"]}),{array => ["a","b","c","d","D"]},"uniq field";

done_testing 2;
