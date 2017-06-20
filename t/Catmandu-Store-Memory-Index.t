#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::Memory;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Memory::Index';
    use_ok $pkg;
}

require_ok $pkg;

my $store = Catmandu::Store::File::Memory->new();
my $index;

note("index");
{
    $index = $store->bag();

    ok $index , 'got the index bag';
}

note("add");
{
    ok $index->add({_id => '1'}), 'add({_id => 1})';
    ok $index->add({_id => '2'}), 'add({_id => 2})';
    ok $index->add({_id => '3'}), 'add({_id => 3})';
}

note("list");
{
    my $array = [sort @{$index->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [1, 2, 3], 'got correct response';
}

note("exists");
{
    for (1 .. 3) {
        ok $index->exists($_), "exists($_)";
    }
}

note("get");
{
    for (1 .. 3) {
        ok $index->get($_), "get($_)";
    }
}

note("delete");
{
    ok $index->delete('1'), 'delete(1)';
}

note("delete_all");
{
    lives_ok {$index->delete_all()} 'delete_all';

    my $array = $index->to_array;

    is_deeply $array , [], 'got correct response';
}

done_testing();
