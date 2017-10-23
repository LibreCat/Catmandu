#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Plugin::Readonly';
    use_ok $pkg;
}
require_ok $pkg;

note("stores");

my $store = Catmandu::Store::Hash->new(
    bags => {data => {plugins => [qw(Readonly)]}});

ok $store->does('Catmandu::Store'),
    'create Catmandu-Store with Readonly plugin';

ok $store->bag->add({_id => '001', name => 'Penguin'}), 'store something';

ok ! $store->bag->get('001'), 'didn\'t store anything';

ok $store->bag->delete('001'), 'delete something';

ok $store->drop , 'drop database';

note("throw errors");

$store = Catmandu::Store::Hash->new(
    default_plugins => [qw(Readonly)] ,
    default_options => { readonly_throw_error => 1 }
);

ok $store->does('Catmandu::Store'),
    'create Catmandu-Store with Readonly plugin';

throws_ok {
    $store->bag->add({_id => '001', name => 'Penguin'})
} 'Catmandu::NotImplemented' , 'store something';

ok ! $store->bag->get('001');

throws_ok {
    $store->bag->delete('001')
} 'Catmandu::NotImplemented' , 'delete something';

throws_ok {
    $store->drop
} 'Catmandu::NotImplemented' , 'drop database';

done_testing;
