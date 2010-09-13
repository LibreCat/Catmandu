#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Importer'; }
require_ok 'Catmandu::Importer';

throws_ok { Catmandu::Importer->new() } qr/Driver is required/, 'no driver given';
throws_ok { Catmandu::Importer->new("ChunkyBacon") } qr/Can't load driver/, 'nonexistent driver given';
throws_ok { Catmandu::Importer->new("Chunky::Bacon") } qr/Can't load driver/, 'nonexistent driver given';

