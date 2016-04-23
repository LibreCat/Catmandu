#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;

my $bag
    = Catmandu::Store::Hash->new(bags => {data => {id_generator => 'Mock'}})
    ->bag;
isa_ok $bag->id_generator, 'Catmandu::IdGenerator::Mock';
$bag->add_many([{}, {}, {}]);
is_deeply $bag->pluck('_id')->to_array, [0, 1, 2];

done_testing;

