#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::paste';
    use_ok $pkg;
}

is_deeply
    $pkg->new('my.field', 'a', 'b', 'c')->fix({a => 'A', b => 'B' , c => 'C'}),
    {my => {field => 'A B C'}, a => 'A', b => 'B' , c => 'C'} , 'paste paths';

is_deeply
    $pkg->new('my.field', 'a', 'b', 'c', join_char => '/')->fix({a => 'A', b => 'B' , c => 'C'}),
    {my => {field => 'A/B/C'}, a => 'A', b => 'B' , c => 'C'} , 'join_char';

is_deeply
    $pkg->new('my.field', 'a', '~b', 'c')->fix({a => 'A', b => 'B' , c => 'C'}),
    {my => {field => 'A b C'}, a => 'A', b => 'B' , c => 'C'} , 'literal strings';

done_testing 4;
