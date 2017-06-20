#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Plugin::SideCar';
    use_ok $pkg;
}
require_ok $pkg;

note("Combined Simple + Hash sidecar");
{
    my $store = Catmandu->store(
        'File::Simple',
        root    => 't/data3',
        keysize => 9,
        bags    => {
            index =>
                {plugins => [qw(SideCar)], sidecar => {package => "Hash"}}
        }
    );

    my $index = $store->bag;

    ok $store , 'got a store';
    ok $index , 'got an index';

    note("...exists");
    ok !$index->exists('1234');

    note("...add");
    ok $index->add({_id => 1234, foo => 'bar', test => [1, 2, 3]}),
        'adding bag `1234`';

    ok -d "t/data3/000/001/234";

    note("...get");

    my $item = $index->get('1234');

    ok $item;

    is_deeply $item , {_id => 1234, foo => 'bar', test => [1, 2, 3]},
        'found combined metadata and file data';

    note("...bag");
    my $container = $store->bag('1234');

    ok $container , 'got bag(1234)';

    note("...upload");
    ok $container->upload(IO::File->new('t/data2/000/000/001/test.txt'),
        'test1.txt');

    ok -f 't/data3/000/001/234/test1.txt', 'test1.txt exists (2)';

    note("...list");
    my $array = [sort @{$container->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test1.txt)], 'got correct response';

    note("...exists");
    ok $container->exists("test1.txt"), "exists(test1.txt)";

    note("...get");
    my $file = $container->get("test1.txt");

    ok $file;

    note("...stream");
    my $str = $container->as_string_utf8($file);

    ok $str , 'can stream the data';

    is $str , "钱唐湖春行\n", 'got the correct data';

    note("...delete_all (bag)");

    lives_ok {$container->delete_all()} 'delete_all';

    $array = $container->to_array;

    is_deeply $array , [], 'got correct response';

    ok !-f 't/data/000/001/234/test1.txt',  'test1.txt doesnt exists (1)';
    ok !-f 't/data3/000/001/234/test1.txt', 'test1.txt doesnt exists (2)';

    note("...delete_all (index)");
    lives_ok {$index->delete_all()} 'delete_all';

    $array = $index->to_array;

    is_deeply $array , [], 'got correct response';
}

note("Combined Hash + Simple sidecar");
{
    my $store = Catmandu->store(
        'Hash',
        bags => {
            data => {
                plugins => [qw(SideCar)],
                sidecar => {
                    package => "File::Simple",
                    options => {'root' => 't/data3', 'keysize' => 9,}
                },
                sidecar_bag => 'index'
            }
        }
    );

    ok $store , 'got a store';

    ok $store->bag->add({_id => '1234', name => 'patrick'}),
        'adding a record';

    note("...upload");
    ok $store->bag->files('1234')
        ->upload(IO::File->new('t/data2/000/000/001/test.txt'), 'test1.txt');

    ok -f 't/data3/000/001/234/test1.txt', 'test1.txt exists (2)';

    note("...get");
    my $file = $store->bag->files('1234')->get("test1.txt");

    ok $file;

    note("...stream");
    my $str = $store->bag->files('1234')->as_string_utf8($file);

    ok $str , 'can stream the data';

    is $str , "钱唐湖春行\n", 'got the correct data';

    note("...drop");
    lives_ok {$store->bag->drop} 'delete_all';

    my $array = $store->bag->to_array;

    is_deeply $array , [], 'got correct response';
}

done_testing;
