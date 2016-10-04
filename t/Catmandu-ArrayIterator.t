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

is $it->contains({n => 2}), 1;

is $it->contains(10), 0;

# test external iteration again because of circular dependency
is_deeply $it->next, {n => 1};
is_deeply $it->next, {n => 2};
$it->rewind;
is_deeply $it->next, {n => 1};

$it->rewind;

my $count = 0;
$it->each(
    sub {
        is shift->{n}, ++$count, "each ($count)";
    }
);

$it->rewind;

$count = 0;
$it->each_until(
    sub {
        is shift->{n}, ++$count, "each ($count)";
        return $count == 2 ? undef : 1;
    }
);

done_testing 15;
