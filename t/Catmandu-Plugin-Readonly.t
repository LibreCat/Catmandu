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

my ($ret, $err) = $store->bag->add({_id => '001', name => 'Penguin'});

ok !defined($ret), 'add returned undef';
isa_ok $err, 'Catmandu::NotImplemented';

($ret, $err) = $store->bag->get('001');

ok !defined($ret), 'get returned undef';
ok !defined($err), 'no error thrown';

($ret, $err) = $store->bag->delete('001');

ok !defined($ret), 'delete returned undef';
isa_ok $err, 'Catmandu::NotImplemented';

($ret, $err) = $store->drop;

ok !defined($ret), 'drop returned undef';
isa_ok $err, 'Catmandu::NotImplemented';

done_testing;
