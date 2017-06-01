#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;
use Catmandu::Store::Simple;
use Catmandu::Store::Memory;
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
    my $store = $pkg->new(stores => $stores);
    my $bag = $store->bag;

    $bag->add_many($data);
    is_deeply $bag->to_array, $data;
    is_deeply $stores->[0]->bag->to_array, $data;
    is_deeply $stores->[1]->bag->to_array, $data;

    is_deeply $bag->get('123'), $data->[0];
    is_deeply $stores->[0]->bag->get('123'), $data->[0];
    is_deeply $stores->[1]->bag->get('123'), $data->[0];

    $bag->delete('123');
    is_deeply $bag->first, $data->[1];
    is_deeply $stores->[0]->bag->first, $data->[1];
    is_deeply $stores->[1]->bag->first, $data->[1];

    $bag->delete_all;
    is $bag->count, 0;
    is $stores->[0]->bag->count, 0;
    is $stores->[1]->bag->count, 0;

    $bag->add_many($data);
    $bag->drop;
    is $bag->count, 0;
}

# note("Simple stores");
# {
#     my $stores = [
#         Catmandu::Store::Simple->new( root => 't/data' ) ,
#         Catmandu::Store::Simple->new( root => 't/data3' ) ,
#     ];
#
#     my $store = $pkg->new(stores => $stores);
#     my $index = $store->bag;
#
#     ok $store , 'got a store';
#     ok $index , 'got an index';
#
#     note("...exists");
#     ok ! $index->exists('1234');
#
#     note("...add");
#     ok $index->add({ _id => 1234 }) , 'adding bag `1234`';
#
#     ok -d "t/data/000/001/234";
#     ok -d "t/data3/000/001/234";
#
#     note("...bag");
#     my $bag   = $store->bag('1234');
#
#     ok $bag , 'got bag(1234)';
#
#     note("...upload");
#     ok $bag->upload(IO::File->new('t/data2/000/000/001/test.txt'), 'test1.txt');
#
#     ok -f 't/data/000/001/234/test1.txt' , 'test1.txt exists (1)';
#     ok -f 't/data3/000/001/234/test1.txt' , 'test1.txt exists (2)';
#
#     note("...list");
#     my $array = [ sort @{$bag->map(sub { shift->{_id} })->to_array} ];
#
#     ok $array , 'list got a response';
#
#     is_deeply $array , [qw(test1.txt)] , 'got correct response';
#
#     note("...exists");
#     ok $bag->exists("test1.txt") , "exists(test1.txt)";
#
#     note("...get");
#     my $file = $bag->get("test1.txt");
#
#     ok $file;
#
#     note("...stream");
#     my $str  = $bag->as_string_utf8($file);
#
#     ok $str , 'can stream the data';
#
#     is $str , "钱唐湖春行\n" , 'got the correct data';
#
#     note("...delete_all (bag)");
#
#     lives_ok { $bag->delete_all() } 'delete_all';
#
#     $array = $bag->to_array;
#
#     is_deeply $array , [] , 'got correct response';
#
#     ok ! -f 't/data/000/001/234/test1.txt' , 'test1.txt doesnt exists (1)';
#     ok ! -f 't/data3/000/001/234/test1.txt' , 'test1.txt doesnt exists (2)';
#
#     note("...delete_all (index)");
#     lives_ok { $index->delete_all() } 'delete_all';
#
#     $array = $index->to_array;
#
#     is_deeply $array , [] , 'got correct response';
# }
#
# note("Combined Simple + Hash stores");
# {
#     my $stores = [
#         Catmandu::Store::Simple->new( root => 't/data3' ) ,
#         Catmandu::Store::Hash->new,
#     ];
#
#     my $store = $pkg->new(stores => $stores);
#     my $index = $store->bag;
#
#     ok $store , 'got a store';
#     ok $index , 'got an index';
#
#     note("...exists");
#     ok ! $index->exists('1234');
#
#     note("...add");
#     ok $index->add({ _id => 1234 , foo => 'bar' , test => [1,2,3] }) , 'adding bag `1234`';
#
#     ok -d "t/data3/000/001/234";
#
#     note("...get");
#
#     my $item = $index->get('1234');
#
#     ok $item;
#
#     is_deeply $item , {
#         _id => 1234 ,
#         foo => 'bar' ,
#         test => [1,2,3]
#     } , 'found combined metadata and file data';
#
#     note("...bag");
#     my $container   = $store->bag('1234');
#
#     ok $container , 'got bag(1234)';
#
#     note("...upload");
#     ok $container->upload(IO::File->new('t/data2/000/000/001/test.txt'), 'test1.txt');
#
#     ok -f 't/data3/000/001/234/test1.txt' , 'test1.txt exists (2)';
#
#     note("...list");
#     my $array = [ sort @{$container->map(sub { shift->{_id} })->to_array} ];
#
#     ok $array , 'list got a response';
#
#     is_deeply $array , [qw(test1.txt)] , 'got correct response';
#
#     note("...exists");
#     ok $container->exists("test1.txt") , "exists(test1.txt)";
#
#     note("...get");
#     my $file = $container->get("test1.txt");
#
#     ok $file;
#
#     note("...stream");
#     my $str  = $container->as_string_utf8($file);
#
#     ok $str , 'can stream the data';
#
#     is $str , "钱唐湖春行\n" , 'got the correct data';
#
#     note("...delete_all (bag)");
#
#     lives_ok { $container->delete_all() } 'delete_all';
#
#     $array = $container->to_array;
#
#     is_deeply $array , [] , 'got correct response';
#
#     ok ! -f 't/data/000/001/234/test1.txt' , 'test1.txt doesnt exists (1)';
#     ok ! -f 't/data3/000/001/234/test1.txt' , 'test1.txt doesnt exists (2)';
#
#     note("...delete_all (index)");
#     lives_ok { $index->delete_all() } 'delete_all';
#
#     $array = $index->to_array;
#
#     is_deeply $array , [] , 'got correct response';
# }
#
# note("Combined Hash + Simple stores");
# {
#     my $stores = [
#         Catmandu::Store::Hash->new,
#         Catmandu::Store::Simple->new( root => 't/data3' ) ,
#     ];
#
#     my $store = $pkg->new(stores => $stores);
#     my $index = $store->bag;
#
#     ok $store , 'got a store';
#     ok $index , 'got an index';
#
#     note("...exists");
#     ok ! $index->exists('1234');
#
#     note("...add");
#     ok $index->add({ _id => 1234 , foo => 'bar' , test => [1,2,3] }) , 'adding bag `1234`';
#
#     ok -d "t/data3/000/001/234";
#
#     note("...get");
#
#     my $item = $index->get('1234');
#
#     ok $item;
#
#     is_deeply $item , {
#         _id => 1234 ,
#         foo => 'bar' ,
#         test => [1,2,3]
#     } , 'found combined metadata and file data';
#
#     note("...bag");
#     my $container   = $store->bag('1234');
#
#     ok $container , 'got bag(1234)';
#
#     note("...upload");
#     ok $container->upload(IO::File->new('t/data2/000/000/001/test.txt'), 'test1.txt');
#
#     ok -f 't/data3/000/001/234/test1.txt' , 'test1.txt exists (2)';
#
#     note("...list");
#     my $array = [ sort @{$container->map(sub { shift->{_id} })->to_array} ];
#
#     ok $array , 'list got a response';
#
#     is_deeply $array , [qw(test1.txt)] , 'got correct response';
#
#     note("...exists");
#     ok $container->exists("test1.txt") , "exists(test1.txt)";
#
#     note("...get");
#     my $file = $container->get("test1.txt");
#
#     ok $file;
#
#     note("...stream");
#     my $str  = $container->as_string_utf8($file);
#
#     ok $str , 'can stream the data';
#
#     is $str , "钱唐湖春行\n" , 'got the correct data';
#
#     note("...delete_all (bag)");
#
#     lives_ok { $container->delete_all() } 'delete_all';
#
#     $array = $container->to_array;
#
#     is_deeply $array , [] , 'got correct response';
#
#     ok ! -f 't/data/000/001/234/test1.txt' , 'test1.txt doesnt exists (1)';
#     ok ! -f 't/data3/000/001/234/test1.txt' , 'test1.txt doesnt exists (2)';
#
#     note("...delete_all (index)");
#     lives_ok { $index->delete_all() } 'delete_all';
#
#     $array = $index->to_array;
#
#     is_deeply $array , [] , 'got correct response';
# }

done_testing;
