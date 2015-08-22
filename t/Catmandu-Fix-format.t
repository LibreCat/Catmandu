#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::format';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name','<%-10s>')->fix({name => 'Joe'}),
    {name => "<Joe       >"},
    "formatted strings";

is_deeply
    $pkg->new('names','<%-10s> <%-10s>')->fix({names => ['Alice','Bob']}),
    {names => "<Alice     > <Bob       >"},
    "formatted arrays";

is_deeply
    $pkg->new('data','<%-10s> <%-10s>')->fix({data => { name => "Alice"}}),
    {data => "<name      > <Alice     >"},
    "formatted hashes";

done_testing 4;