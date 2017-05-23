#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Simple;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::Simple::Index';
    use_ok $pkg;
}

require_ok $pkg;

my $store = Catmandu::Store::Simple->new(root => 't/data2');
my $bags;

note("bags");
{
    $bags = $store->bag('bags');

    ok $bags , 'got the "bags" bags';
}

note("list");
{
    my $array = $bags->to_array;

    ok $array , 'list got a response';

    is_deeply $array , [
            { _id => 1 } ,
            { _id => 2 } ,
            { _id => 3 } ,
        ] , 'got correct response';
}

note("exists");
{
    for (1..3) {
        ok $bags->exists($_) , "exists($_)";
        my $zero_key = ("0" x $_) . $_;
        ok $bags->exists($zero_key) , "exists($zero_key)";
    }
}

note("get");
{
    for (1..3) {
        ok $bags->get($_) , "get($_)";
        my $zero_key = ("0" x $_) . $_;
        ok $bags->get($zero_key) , "get($zero_key)";
    }
}

$store = Catmandu::Store::Simple->new(root => 't/data');
$bags  = $store->bag('bags');

note("add");
{
    throws_ok { $bags->add({ }) } 'Catmandu::BadArg' , 'add() fails';
    throws_ok { $bags->add({ _id => 'abcd' }) } 'Catmandu::BadArg' , 'failed to add(abcd)';
    throws_ok { $bags->add({ _id => '1234567890'}) } 'Catmandu::BadArg' , 'failed to add(1234567890)';
    throws_ok { $bags->add({ _id => '00000000001234' }) } 'Catmandu::BadArg' , 'failed to add(00000000001234)';

    my $c = $bags->add({ _id => '1234' });

    ok $c , 'add(1234)';

    ok -d "t/data/000/001/234" , 'found a container on disk';
}


note("delete");
{
    ok $bags->delete('1234') , 'delete(1234)';

    ok ! -d "t/data/000/001/234" , 'container on disk was deleted';
}

note("delete_all");
{
    lives_ok { $bags->delete_all() } 'delete_all';
}

done_testing();
