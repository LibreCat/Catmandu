#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::prepend';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name', 'mr. ')->fix({name => 'smith'}),
    {name => "mr. smith"},
    "prepend to value";

is_deeply
    $pkg->new('names.*.name', 'mr. ')->fix({names => [{name => 'smith'}, {name => 'jones'}]}),
    {names => [{name => 'mr. smith'}, {name => 'mr. jones'}]},
    "prepend to wildcard values";

done_testing 3;
