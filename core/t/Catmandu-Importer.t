#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Importer'; }
require_ok 'Catmandu::Importer';

throws_ok { Catmandu::Importer->new() } qr/Driver is required/, 'no driver given';
throws_ok { Catmandu::Importer->new("ChunkyBacon") } qr/Can't load driver/, 'nonexistent driver given';
throws_ok { Catmandu::Importer->new("Chunky::Bacon") } qr/Can't load driver/, 'nonexistent driver given';

can_ok 'Catmandu::Importer', qw(driver done);
can_ok 'Catmandu::Importer', qw(each);
