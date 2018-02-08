#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::Simple;
use Catmandu::Store::Hash;
use Path::Tiny;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Multi';
    use_ok $pkg;
}
require_ok $pkg;

path("t/tmp/multi/a")->mkpath;
path("t/tmp/multi/b")->mkpath;

note("Simple stores");
{
    my $stores = [
        Catmandu::Store::File::Simple->new(
            root    => 't/tmp/multi/a',
            keysize => 9
        ),
        Catmandu::Store::File::Simple->new(
            root    => 't/tmp/multi/b',
            keysize => 9
        ),
    ];

    my $store = $pkg->new(stores => $stores);
    my $index = $store->bag;

    ok $store , 'got a store';
    ok $index , 'got an index';

    note("...exists");
    ok !$index->exists('6012');

    note("...add");
    ok $index->add({_id => 6012}), 'adding bag `6012`';

    ok -d "t/tmp/multi/a/000/006/012";
    ok -d "t/tmp/multi/b/000/006/012";

    note("...bag");
    my $bag = $store->bag->files('6012');

    ok $bag , 'got bag(6012)';

    note("...upload");
    ok $bag->upload(IO::File->new('t/data2/000/000/001/test.txt'),
        'test1.txt');

    ok -f 't/tmp/multi/a/000/006/012/test1.txt', 'test1.txt exists (1)';
    ok -f 't/tmp/multi/b/000/006/012/test1.txt', 'test1.txt exists (2)';

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

    ok !-f 't/tmp/multi/a/000/006/012/test1.txt',
        'test1.txt doesnt exists (1)';
    ok !-f 't/tmp/multi/b/000/006/012/test1.txt',
        'test1.txt doesnt exists (2)';

    note("...delete_all (index)");
    lives_ok {$index->delete_all()} 'delete_all';

    $array = $index->to_array;

    is_deeply $array , [], 'got correct response';
}

path("t/tmp/multi/a")->remove_tree;
path("t/tmp/multi/b")->remove_tree;

done_testing;
