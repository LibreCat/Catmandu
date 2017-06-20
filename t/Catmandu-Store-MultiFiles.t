#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::Simple;
use Catmandu::Store::Hash;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Multi';
    use_ok $pkg;
}
require_ok $pkg;

note("Simple stores");
{
    my $stores = [
        Catmandu::Store::File::Simple->new(root => 't/data',  keysize => 9),
        Catmandu::Store::File::Simple->new(root => 't/data3', keysize => 9),
    ];

    my $store = $pkg->new(stores => $stores);
    my $index = $store->bag;

    ok $store , 'got a store';
    ok $index , 'got an index';

    note("...exists");
    ok !$index->exists('1234');

    note("...add");
    ok $index->add({_id => 1234}), 'adding bag `1234`';

    ok -d "t/data/000/001/234";
    ok -d "t/data3/000/001/234";

    note("...bag");
    my $bag = $store->bag->files('1234');

    ok $bag , 'got bag(1234)';

    note("...upload");
    ok $bag->upload(IO::File->new('t/data2/000/000/001/test.txt'),
        'test1.txt');

    ok -f 't/data/000/001/234/test1.txt',  'test1.txt exists (1)';
    ok -f 't/data3/000/001/234/test1.txt', 'test1.txt exists (2)';

    note("...list");
    my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test1.txt)], 'got correct response';

    note("...exists");
    ok $bag->exists("test1.txt"), "exists(test1.txt)";

    note("...get");
    my $file = $bag->get("test1.txt");

    ok $file;

    note("...stream");
    my $str = $bag->as_string_utf8($file);

    ok $str , 'can stream the data';

    is $str , "钱唐湖春行\n", 'got the correct data';

    note("...delete_all (bag)");

    lives_ok {$bag->delete_all()} 'delete_all';

    $array = $bag->to_array;

    is_deeply $array , [], 'got correct response';

    ok !-f 't/data/000/001/234/test1.txt',  'test1.txt doesnt exists (1)';
    ok !-f 't/data3/000/001/234/test1.txt', 'test1.txt doesnt exists (2)';

    note("...delete_all (index)");
    lives_ok {$index->delete_all()} 'delete_all';

    $array = $index->to_array;

    is_deeply $array , [], 'got correct response';
}

done_testing;
