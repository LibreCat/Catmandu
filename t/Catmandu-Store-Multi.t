#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::Multi';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
    {_id => '123', name => 'Patrick', age => '39'},
    {_id => '321', name => 'Nicolas', age => '34'},
];

note("Hash stores");
{
    my $stores = [Catmandu::Store::Hash->new, Catmandu::Store::Hash->new,];
    my $store  = $pkg->new(stores => $stores);
    my $bag    = $store->bag;

    $bag->add_many($data);
    is_deeply $bag->to_array,              $data;
    is_deeply $stores->[0]->bag->to_array, $data;
    is_deeply $stores->[1]->bag->to_array, $data;

    is_deeply $bag->get('123'),              $data->[0];
    is_deeply $stores->[0]->bag->get('123'), $data->[0];
    is_deeply $stores->[1]->bag->get('123'), $data->[0];

    $bag->delete('123');
    is_deeply $bag->first,              $data->[1];
    is_deeply $stores->[0]->bag->first, $data->[1];
    is_deeply $stores->[1]->bag->first, $data->[1];

    $bag->delete_all;
    is $bag->count,              0;
    is $stores->[0]->bag->count, 0;
    is $stores->[1]->bag->count, 0;

    $bag->add_many($data);
    $bag->drop;
    is $bag->count, 0;
}

done_testing;
