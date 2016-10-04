#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::set_hash';
    use_ok $pkg;
}

is_deeply $pkg->new('job')->fix({}), {job => {}}, "set hash at root";

is_deeply $pkg->new('deeply.nested.$append.job')->fix({}), {},
    "set hash doesn't create intermediate path";

is_deeply $pkg->new('deeply.nested.*.job')
    ->fix({deeply => {nested => [undef, {}]}}),
    {deeply => {nested => [undef, {job => {}}]}}, "set deeply nested hash";

is_deeply $pkg->new('deeply.nested.$append.job')
    ->fix({deeply => {nested => {}}}), {deeply => {nested => {}}},
    "only set hash if the path matches";

is_deeply $pkg->new('job', 'a', 'b', 'c', 'd')->fix({}),
    {job => {'a' => 'b', 'c' => 'd'}}, "set hash with initial contents";

done_testing 6;
