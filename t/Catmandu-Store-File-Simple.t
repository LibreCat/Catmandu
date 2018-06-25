#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd;
use File::Spec;
use File::Temp;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Simple';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok {$pkg->new} 'dies ok on not enough parameters';

my $t = File::Temp->newdir(EXLOCK => 0, UNLINK => 1);
my $dir = Cwd::abs_path($t->dirname);

my $store = $pkg->new(root => $dir, keysize => 9);

ok $store , 'got a store';

my $bags = $store->bag();

ok $bags , 'store->bag()';

isa_ok $bags , 'Catmandu::Store::File::Simple::Index';

my $expected_path = File::Spec->catdir(
    $dir, "000", "001", "234"
);

is_deeply $store->directory_index->add('1234'), { _id => "000001234", _path => $expected_path }, 'directory_index->add(1234)';
is_deeply $store->directory_index->add('0001234'), { _id => "000001234", _path => $expected_path }, 'directory_index->add(0001234)';
lives_ok sub { $store->directory_index->delete('000001234') }, 'directory_index->delete(000001234)';

dies_ok sub {
    $store->directory_index->add('00000001234');
}, 'directory_index->add(00000001234) must die';

ok !$store->bag('1235'), 'bag(1235) doesnt exist';

lives_ok {$store->bag('1')} 'bag(1) exists';

dies_ok sub {
    $pkg->new(root => $dir, keysize => 13);
}, 'dies on wrong keysize';

lives_ok sub {
    $pkg->new(root => $dir, keysize => 12);
}, 'keysize ok';

#delete all

lives_ok(sub {

    $store->index->delete_all();

}, "delete_all" );

is $store->index->count, 0;

#UUID
$store = $pkg->new( root => $dir, uuid => 1 );
$expected_path = File::Spec->catdir(
    $dir, "018","970","A2-","B1E","8-1","1DF","-A2","E0-","A70","579","F64","438"
);

is_deeply $store->directory_index->add("018970A2-B1E8-11DF-A2E0-A70579F64438"), { _id => "018970A2-B1E8-11DF-A2E0-A70579F64438", _path => $expected_path }, "index->add(018970A2-B1E8-11DF-A2E0-A70579F64438)";

my $uuid_records = $store->index->to_array();

#same directory_index as above
$store = $pkg->new( root => $dir, directory_index_package => "UUID", directory_index_options => +{} );
is_deeply $store->index->to_array, $uuid_records;

done_testing;
