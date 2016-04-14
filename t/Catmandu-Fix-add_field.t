#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::add_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('job', 'fixer')->fix({}),
    {job => "fixer"},
    "add field at root";

is_deeply
    $pkg->new('deeply.nested.$append.job', 'fixer')->fix({}),
    {deeply => {nested => [{job => "fixer"}]}},
    "add field creates intermediate path";

is_deeply
    $pkg->new('deeply.nested.1.job', 'fixer')->fix({}),
    {deeply => {nested => [undef, {job => "fixer"}]}},
    "add field creates intermediate path";

is_deeply
    $pkg->new('deeply.nested.$append.job', 'fixer')->fix({deeply => {nested => {}}}),
    {deeply => {nested => {}}},
    "only add field if the path matches";

is_deeply
    $pkg->new('test', '0123')->fix({}),
    {test => '0123'},
    "add a number";

is_deeply
    $pkg->new('test')->fix({}),
    {test => undef},
    "set key to undef";

done_testing 6;
