#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Plugin::Datestamps';
    use_ok $pkg;
}
require_ok $pkg;

my $store = Catmandu::Store::Hash->new(bags => { data => { plugins => [qw(Datestamps)] } });

ok $store->does('Catmandu::Store')  , 'create Catmandu-Store with Datestamps plugin';
ok $store->bag->add( { _id => '001' , name => 'Penguin' } ) , 'store something';
ok $store->bag->get( '001' ) , 'get 001';
ok $store->bag->get( '001' )->{date_created} , 'has date_created';
ok $store->bag->get( '001' )->{date_updated} , 'has date_updated';

my $created = $store->bag->get( '001' )->{date_created};
my $updated = $store->bag->get( '001' )->{date_updated};
my $obj     = $store->bag->get( '001' );
$obj->{name} = 'John';

sleep 2;

ok $store->bag->add( $obj ) , 'update something';
ok $store->bag->get( '001' )->{date_updated} , 'has date_updated';
ok $store->bag->get( '001' )->{date_updated} ne $updated , 'dates change';
is $store->bag->get( '001' )->{date_created} , $created , 'but created dates dont change';

done_testing 11;

