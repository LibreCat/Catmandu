#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::ArrayIterator';
    use_ok $pkg;
}

my $arr = [{n => 1}, {n => 2}, {n => 3}];
my $it = $pkg->new($arr);

ok $it->does('Catmandu::Iterable');

is_deeply [@{$it}], $arr;

is $it->count, 3;

is_deeply $it->first, $arr->[0];

is ( $it->contains({n=>2}),1);

is ($it->contains(10),0);

done_testing 7;
