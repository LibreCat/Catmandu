#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::string';
    use_ok $pkg;
}

is_deeply $pkg->new('str')->fix({}),                        {};
is_deeply $pkg->new('str')->fix({str => 0}),                {str => "0"};
is_deeply $pkg->new('str')->fix({str => 123}),              {str => "123"};
is_deeply $pkg->new('str')->fix({str => [1, 2]}),           {str => "12"};
is_deeply $pkg->new('str')->fix({str => [1, {2 => 3}]}),    {str => ""};
is_deeply $pkg->new('str')->fix({str => {3 => 4, 1 => 2}}), {str => "24"};
is_deeply $pkg->new('str')->fix({str => {3 => {4 => 5}, 1 => 2}}),
    {str => ""};

done_testing;
