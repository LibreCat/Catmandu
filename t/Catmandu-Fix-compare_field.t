#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::compare_field';
    use_ok $pkg;
}

is_deeply $pkg->new('number',10)->fix({number => 1}), {number => -1};
is_deeply $pkg->new('number',10)->fix({number => 11}), {number => 1};
is_deeply $pkg->new('number',10)->fix({number => 10}), {number => 0};

is_deeply $pkg->new('string', 'ABC', 'string', 1)->fix({string => 'ABB'}), {string => -1};
is_deeply $pkg->new('string', 'ABC', 'string', 1)->fix({string => 'ABD'}), {string => 1};
is_deeply $pkg->new('string', 'ABC', 'string', 1)->fix({string => 'ABC'}), {string => 0};


done_testing 7;