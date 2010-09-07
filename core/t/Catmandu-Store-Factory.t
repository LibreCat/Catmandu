#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN { use_ok('Catmandu::Store::Factory'); }
require_ok('Catmandu::Store::Factory');

use Catmandu::Store::Factory;

my $store = Catmandu::Store::Factory->connect('Mock',file => '/tmp/test.mock');

isa_ok($store,'Catmandu::Store::Mock','connect');

throws_ok { Catmandu::Store::Factory->connect('Xyxyxyxy') } qr{Failed to load driver 'Catmandu::Store::Xyxyxyxy'} , "caught non existing driver";
