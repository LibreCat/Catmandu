#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd;
use File::Spec;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Simple';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok {$pkg->new} 'dies ok on not enough parameters';

my $dir = File::Spec->catdir(
    Cwd::getcwd,
    "t","data2"
);
my $store = $pkg->new(root => $dir, keysize => 9);

ok $store , 'got a store';

my $bags = $store->bag();

ok $bags , 'store->bag()';

isa_ok $bags , 'Catmandu::Store::File::Simple::Index';

my $expected_path = File::Spec->catdir(
    $dir, "000", "001", "234"
);

is $store->id_path->to_path('1234'), $expected_path, 'id_path->to_path(1234)';

is $store->id_path->to_path('0001234'), $expected_path,
    'id_path->to_path(0001234)';

dies_ok sub {
    $store->id_path->to_path('00000001234');
}, 'id_path->to_path(00000001234) must die';

ok !$store->bag('1235'), 'bag(1235) doesnt exist';

lives_ok {$store->bag('1')} 'bag(1) exists';

dies_ok sub {
    $pkg->new(root => $dir, keysize => 13);
}, 'dies on wrong keysize';

lives_ok sub {
    $pkg->new(root => $dir, keysize => 12);
}, 'dies on connecting to a store with the wrong keysize';

done_testing;
