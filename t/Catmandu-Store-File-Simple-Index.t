#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::Simple;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Simple::Index';
    use_ok $pkg;
}

require_ok $pkg;

my $store
    = Catmandu::Store::File::Simple->new(root => 't/data2', keysize => 9);
my $index;

note("index");
{
    $index = $store->bag();

    ok $index , 'got the index bag';
}

note("list");
{
    my $array = $index->to_array;

    ok $array , 'list got a response';

    # Order is not important in a list
    is_deeply [sort({$a->{_id} cmp $b->{_id}} @$array)],
        [{_id => 1}, {_id => 2}, {_id => 3},], 'got correct response';
}

note("exists");
{
    for (1 .. 3) {
        ok $index->exists($_), "exists($_)";
        my $zero_key = ("0" x $_) . $_;
        ok $index->exists($zero_key), "exists($zero_key)";
    }
}

note("get");
{
    for (1 .. 3) {
        ok $index->get($_), "get($_)";
        my $zero_key = ("0" x $_) . $_;
        ok $index->get($zero_key), "get($zero_key)";
    }
}

$store = Catmandu::Store::File::Simple->new(root => 't/data', keysize => 9);
$index = $store->bag();

note("add");
{
    throws_ok {$index->add({_id => 'abcd'})} 'Catmandu::BadArg',
        'failed to add(abcd)';
    throws_ok {$index->add({_id => '1234567890'})} 'Catmandu::BadArg',
        'failed to add(1234567890)';
    throws_ok {$index->add({_id => '00000000001234'})} 'Catmandu::BadArg',
        'failed to add(00000000001234)';

    my $c = $index->add({_id => '1234'});

    ok $c , 'add(1234)';

    ok -d "t/data/000/001/234", 'found a container on disk';
}

note("delete");
{
    ok $index->delete('1234'), 'delete(1234)';

    ok !-d "t/data/000/001/234", 'container on disk was deleted';
}

note("delete_all");
{
    lives_ok {$index->delete_all()} 'delete_all';
}

done_testing();
