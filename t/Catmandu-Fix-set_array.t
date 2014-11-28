#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::set_array';
    use_ok $pkg;
}

is_deeply
    $pkg->new('job')->fix({}),
    {job => []},
    "set field at root";

is_deeply
    $pkg->new('deeply.nested.$append.job')->fix({}),
    {},
    "set field doesn't create intermediate path";

is_deeply
    $pkg->new('deeply.nested.*.job')->fix({deeply => {nested => [undef, {}]}}),
    {deeply => {nested => [undef, {job => []}]}},
    "set deeply nested field";

is_deeply
    $pkg->new('deeply.nested.$append.job')->fix({deeply => {nested => {}}}),
    {deeply => {nested => {}}},
    "only set field if the path matches";

done_testing 5;
