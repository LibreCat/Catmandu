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

my $store = Catmandu::Store::Hash->new(
    bags => {data => {plugins => [qw(Datestamps)]}});

ok $store->does('Catmandu::Store'),
    'create Catmandu-Store with Datestamps plugin';
ok $store->bag->add({_id => '001', name => 'Penguin'}), 'store something';
ok $store->bag->get('001'),                             'get 001';
ok $store->bag->get('001')->{date_created},             'has date_created';
ok $store->bag->get('001')->{date_updated},             'has date_updated';

my $created = $store->bag->get('001')->{date_created};
my $updated = $store->bag->get('001')->{date_updated};
my $rec     = $store->bag->get('001');
$rec->{name} = 'John';

sleep 2;

ok $store->bag->add($rec), 'update something';
$rec = $store->bag->get('001');
ok $rec->{date_updated},             'has date_updated';
ok $rec->{date_updated} ne $updated, 'dates change';
is $rec->{date_created}, $created, 'but created dates dont change';

# formats
like $rec->{date_created}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;
like $rec->{date_updated}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;

$store = Catmandu::Store::Hash->new(
    bags => {
        data => {
            plugins          => [qw(Datestamps)],
            datestamp_format => 'iso_date_time'
        }
    }
);
$store->bag->add({_id => '001', name => 'Penguin'});
$rec = $store->bag->get('001');
like $rec->{date_created}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;

$store = Catmandu::Store::Hash->new(
    bags => {
        data => {
            plugins          => [qw(Datestamps)],
            datestamp_format => 'iso_date_time_millis'
        }
    }
);
$store->bag->add({_id => '001', name => 'Penguin'});
$rec = $store->bag->get('001');
like $rec->{date_created}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/;

$store = Catmandu::Store::Hash->new(
    bags => {
        data => {plugins => [qw(Datestamps)], datestamp_format => '%Y/%m/%d'}
    }
);
$store->bag->add({_id => '001', name => 'Penguin'});
$rec = $store->bag->get('001');
like $rec->{date_created}, qr/^\d{4}\/\d{2}\/\d{2}/;

#fields
$store = Catmandu::Store::Hash->new(
    bags => {
        data => {
            plugins                 => [qw(Datestamps)],
            datestamp_created_field => 'created',
            datestamp_updated_field => 'updated'
        }
    }
);
$store->bag->add({_id => '001', name => 'Penguin'});
$rec = $store->bag->get('001');
like $rec->{created}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;
like $rec->{updated}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;

done_testing;

