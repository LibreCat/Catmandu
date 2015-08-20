#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::reverse';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name')->fix({name => 'joe'}),
    {name => "eoj"},
    "reverse string";

is_deeply
    $pkg->new('numbers')->fix({numbers => [1,2,3,4]}),
    {numbers => [4,3,2,1]},
    "reverse array";

done_testing 3;