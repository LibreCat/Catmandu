#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Plugin::Versioning';
    use_ok $pkg;
}
require_ok $pkg;

my $store = Catmandu::Store::Hash->new(bags => { data => { plugins => [qw(Versioning)] } });

ok $store->does('Catmandu::Store')  , 'create Catmandu-Store with Versioning plugin';
ok $store->bag->add( { _id => '001' , name => 'Penguin' } ) , 'store something';

my $obj = $store->bag->get( '001' );

ok $obj , 'get 001';
is $obj->{name} , 'Penguin' , 'get values';

$obj->{name} = 'Polar Bear';
ok $store->bag->add($obj) , 'change object and store';
is $store->bag->get('001')->{name} , 'Polar Bear' , 'check change';

ok $store->bag->get_history('001') , 'get_history';
is @{ $store->bag->get_history('001') } , 2 , 'one item in history';
my $version = $store->bag->get_history('001')->[0];
is $version->{name} , 'Polar Bear' , 'correct item in history';

ok $store->bag->get_version('001',1) , 'get_version 1';
is $store->bag->get_version('001',1)->{name} , 'Penguin' , 'get_version 1 name';

ok $store->bag->get_previous_version('001') , 'get_previous_version';
is $store->bag->get_previous_version('001')->{name} , 'Penguin' , 'get_previous_version name';

ok $store->bag->restore_version('001',1) , 'restore_version';
is $store->bag->get('001')->{name} , 'Penguin' , 'check restore version';

# reset
ok $store->bag->add($obj) , 'reset';
is $store->bag->get('001')->{name} , 'Polar Bear' , 'check change';

ok $store->bag->restore_previous_version('001') , 'restore_previous_version';
is $store->bag->get('001')->{name} , 'Penguin' , 'check restore version';

done_testing 21;