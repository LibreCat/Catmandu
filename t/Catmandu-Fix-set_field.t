#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::set_field';
    use_ok $pkg;
}

is_deeply $pkg->new('job', 'fixer')->fix({}), {job => "fixer"},
    "set field at root";

is_deeply $pkg->new('deeply.nested.$append.job', 'fixer')->fix({}), {},
    "set field doesn't create intermediate path";

is_deeply $pkg->new('deeply.nested.*.job', 'fixer')
    ->fix({deeply => {nested => [undef, {}]}}),
    {deeply => {nested => [undef, {job => "fixer"}]}},
    "set deeply nested field";

is_deeply $pkg->new('deeply.nested.$append.job', 'fixer')
    ->fix({deeply => {nested => {}}}), {deeply => {nested => {}}},
    "only set field if the path matches";

is_deeply $pkg->new('test', '0123')->fix({test => 'ok'}), {test => '0123'},
    "set a number";

is_deeply $pkg->new('test')->fix({}), {test => undef}, "set key to undef";

is_deeply $pkg->new("'a'", 'test')->fix({}), {a => 'test'},
    "add a single quoted field";

is_deeply $pkg->new("\"a\"", 'test')->fix({}), {a => 'test'},
    "add a double quoted field";

is_deeply $pkg->new("\"a b c\"", 'test')->fix({}), {"a b c" => 'test'},
    "add a double quoted field with spaces";

done_testing;
