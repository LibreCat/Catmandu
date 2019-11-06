#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $ENV{ENVTEST} = "bar";
    $pkg = 'Catmandu::Fix::env';
    use_ok $pkg;
}

is_deeply $pkg->new('foo', 'ENVTEST')->fix({}), {foo => "bar"},
    "add field at root";

is_deeply $pkg->new('deeply.nested.$append.job', 'ENVTEST')->fix({}),
    {deeply => {nested => [{job => "bar"}]}},
    "add field creates intermediate path";

is_deeply $pkg->new('deeply.nested.1.job', 'ENVTEST')->fix({}),
    {deeply => {nested => [undef, {job => "bar"}]}},
    "add field creates intermediate path";

is_deeply $pkg->new('deeply.nested.$append.job', 'ENVTEST')
    ->fix({deeply => {nested => {}}}), {deeply => {nested => {}}},
    "only add field if the path matches";

done_testing;
