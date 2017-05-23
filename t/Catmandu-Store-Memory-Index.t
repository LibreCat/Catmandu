#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Memory;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::Memory::Index';
    use_ok $pkg;
}

require_ok $pkg;

my $store = Catmandu::Store::Memory->new();
my $bags;

note("bags");
{
    $bags = $store->bag('bags');

    ok $bags , 'got the "bags" bags';
}

note("add");
{
    throws_ok { $bags->add({ }) } 'Catmandu::BadArg' , 'add() fails';
    ok $bags->add({ _id => '1' }) , 'add({_id => 1})';
    ok $bags->add({ _id => '2' }) , 'add({_id => 2})';
    ok $bags->add({ _id => '3' }) , 'add({_id => 3})';
}

note("list");
{
    my $array = [ sort @{$bags->map(sub { shift->{_id} })->to_array} ];

    ok $array , 'list got a response';

    is_deeply $array , [ 1, 2, 3] , 'got correct response';
}

note("exists");
{
    for (1..3) {
        ok $bags->exists($_) , "exists($_)";
    }
}

note("get");
{
    for (1..3) {
        ok $bags->get($_) , "get($_)";
    }
}

note("delete");
{
    ok $bags->delete('1') , 'delete(1)';
}

note("delete_all");
{
    lives_ok { $bags->delete_all() } 'delete_all';

    my $array = $bags->to_array;

    is_deeply $array , [] , 'got correct response';
}

done_testing();
