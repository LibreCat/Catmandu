#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::ArrayIterator;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::MultiIterator';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {n => 0},
   {n => 1},
   {n => 2},
];

my $it = $pkg->new(
    Catmandu::ArrayIterator->new($data),
    Catmandu::ArrayIterator->new($data),
);

isa_ok $it, $pkg;

is_deeply $it->to_array, [@$data, @$data];

done_testing;

