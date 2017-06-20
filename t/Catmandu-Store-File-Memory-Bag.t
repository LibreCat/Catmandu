#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::String;
use Catmandu::Util qw(:io);
use Catmandu::Store::File::Memory;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Memory::Bag';
    use_ok $pkg;
}

require_ok $pkg;

my $store = Catmandu::Store::File::Memory->new;
my $index = $store->bag;

ok $store , 'got a store';
ok $index , 'got an index';

ok $index->add({_id => 1234}), 'adding bag `1234`';

my $bag = $store->bag('1234');

ok $bag , 'got bag(1234)';

note("add");
{
    ok $bag->upload(io('t/data2/000/000/001/test.txt'), 'test1.txt');
    ok $bag->upload(io('t/data2/000/000/002/test.txt'), 'test2.txt');
    ok $bag->upload(io('t/data2/000/000/003/test.txt'), 'test3.txt');
}

note("list");
{
    my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test1.txt test2.txt test3.txt)],
        'got correct response';
}

note("exists");
{
    for (1 .. 3) {
        ok $bag->exists("test" . $_ . ".txt"), "exists(test" . $_ . ".txt)";
    }
}

note("get");
{
    for (1 .. 3) {
        ok $bag->get("test" . $_ . ".txt"), "get(test" . $_ . ".txt)";
    }

    my $file = $bag->get("test1.txt");

    my $str;
    my $io = IO::String->new($str);

    ok $bag->stream($io, $file), 'can stream the data';

    is $str , "钱唐湖春行\n", 'got the correct data';
}

note("delete");
{
    ok $bag->delete('test1.txt'), 'delete(test1.txt)';

    my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test2.txt test3.txt)], 'got correct response';
}

note("delete_all");
{
    lives_ok {$bag->delete_all()} 'delete_all';

    my $array = $bag->to_array;

    is_deeply $array , [], 'got correct response';
}

done_testing();
