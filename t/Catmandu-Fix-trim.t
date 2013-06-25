#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::trim';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name')->fix({name => "\tjoe  "}),
    {name => "joe"},
    "trim whitespace";

is_deeply
    $pkg->new('name', 'whitespace')->fix({name => "\t / joe  "}),
    {name => "/ joe"},
    "trim whitespace";

is_deeply
    $pkg->new('name', 'nonword')->fix({name => "/\tjoe  .  "}),
    {name => "joe"},
    "trim nonword characters";

is_deeply
    $pkg->new('names.*.name')->fix({names => [{name => "\tjoe  "}, {name => "  rick  "}]}),
    {names => [{name => "joe"}, {name => "rick"}]},
    "trim wildcard values";

done_testing 5;
