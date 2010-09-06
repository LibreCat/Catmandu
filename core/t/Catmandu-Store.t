#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok('Catmandu::Store'); }
require_ok('Catmandu::Store');

use Catmandu::Store;

my $store = Catmandu::Store->connect();

isa_ok($store,'Catmandu::Store','Catmandu::Store->connect');

my $obj = $store->load(1);

ok(defined $obj,'load');

$obj->{name} = 'test';

ok(defined $store->save($obj), 'save');

ok(defined $store->each, 'list');

ok(defined $store->delete($obj));
