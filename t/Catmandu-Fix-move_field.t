#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::move_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('old', 'new')->fix({old => 'old'}),
    {new => 'old'},
    "move field at root";

is_deeply
    $pkg->new('old', 'deeply.nested.$append.new')->fix({old => 'old'}),
    {deeply => {nested => [{new => 'old'}]}},
    "move field creates intermediate path";

done_testing 3;
