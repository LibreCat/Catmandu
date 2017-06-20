#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Simple';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok {$pkg->new} 'dies ok on not enough parameters';

my $store = $pkg->new(root => 't/data2', keysize => 9);

ok $store , 'got a store';

my $bags = $store->bag();

ok $bags , 'store->bag()';

isa_ok $bags , 'Catmandu::Store::File::Simple::Index';

is $store->path_string('1234'), 't/data2/000/001/234', 'path_string(1234)';

is $store->path_string('0001234'), 't/data2/000/001/234',
    'path_string(0001234)';

ok !$store->path_string('00000001234'), 'path_string(00000001234) fails';

throws_ok {$store->bag('1235')} 'Catmandu::Error', 'bag(1235) doesnt exist';

lives_ok {$store->bag('1')} 'bag(1) exists';

dies_ok sub {
    $pkg->new(root => 't/data2', keysize => 13);
}, 'dies on wrong keysize';

lives_ok sub {
    $pkg->new(root => 't/data2', keysize => 12);
}, 'dies on connecting to a store with the wrong keysize';

done_testing;
