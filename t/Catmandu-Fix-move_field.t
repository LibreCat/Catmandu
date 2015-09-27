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

is_deeply
    $pkg->new('old', 'new.$prepend')->fix({old => 'hello',new => ['world']}),
    {new => ['hello','world']} ,
    "move field creates intermediate path";

is_deeply
    $pkg->new('old', 'new.$append')->fix({old => 'hello',new => ['world']}),
    {new => ['world','hello']} ,
    "move field creates intermediate path";

done_testing 5;
