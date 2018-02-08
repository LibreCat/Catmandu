#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::Simple;
use Catmandu::Store::File::Multi;
use Path::Tiny;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Multi::Index';
    use_ok $pkg;
}

require_ok $pkg;

my $stores
    = [Catmandu::Store::File::Simple->new(root => 't/data2', keysize => 9),];

my $store = Catmandu::Store::File::Multi->new(stores => $stores);
my $index;

note("index");
{
    $index = $store->index();

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

path("t/tmp/multi-index/a")->mkpath;
path("t/tmp/multi-index/b")->mkpath;

$stores = [
    Catmandu::Store::File::Simple->new(
        root    => 't/tmp/multi-index/a',
        keysize => 9
    ),
    Catmandu::Store::File::Simple->new(
        root    => 't/tmp/multi-index/b',
        keysize => 9
    ),
];

$store = Catmandu::Store::File::Multi->new(stores => $stores);
$index = $store->index();

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

    ok -d "t/tmp/multi-index/a/000/001/234", 'found a container on disk';
}

note("delete");
{
    ok $index->delete('1234'), 'delete(1234)';

    ok !-d "t/tmp/multi-index/a/000/001/234", 'container on disk was deleted';
}

note("delete_all");
{
    lives_ok {$index->delete_all()} 'delete_all';
}

path("t/tmp/multi-index/a")->remove_tree;
path("t/tmp/multi-index/b")->remove_tree;

done_testing();
