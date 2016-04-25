#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::random';
    use_ok $pkg;
}

is_deeply
    $pkg->new('random', '1')->fix({}),
    {random => 0},
    "add random field at root";

is_deeply
    $pkg->new('deeply.nested.$append.random', '1')->fix({}),
    {deeply => {nested => [{random => 0}]}},
    "add field creates intermediate path";

is_deeply
    $pkg->new('deeply.nested.1.random', '1')->fix({}),
    {deeply => {nested => [undef, {random => 0}]}},
    "add field creates intermediate path";

is_deeply
    $pkg->new('deeply.nested.$append.random', '1')->fix({deeply => {nested => {}}}),
    {deeply => {nested => {}}},
    "only add field if the path matches";

like $pkg->new('random', '10')->fix({})->{random}, qr/^[0-9]$/ , "add a random number";

done_testing 6;
