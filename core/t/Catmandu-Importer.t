#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('Catmandu::Importer'); }
require_ok('Catmandu::Importer');

use Catmandu::Importer;

my $importer = Catmandu::Importer->open();

isa_ok($importer,'Catmandu::Importer','Catmandu::Importer->open');

my $obj = $importer->next();

ok(defined $obj, 'next');

ok(ref $obj eq 'HASH', 'next is a HASH');

is($importer->close,1,'close');
