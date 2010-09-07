#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok('Catmandu::Importer'); }
require_ok('Catmandu::Importer');

use Catmandu::Importer;

my $importer = Catmandu::Importer->open();

isa_ok($importer,'Catmandu::Importer','Catmandu::Importer->open');

my $count = $importer->each();

is($count, 0, 'each');

is($importer->close,1,'close');
