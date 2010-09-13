#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Exporter'; }
require_ok 'Catmandu::Exporter';

throws_ok { Catmandu::Exporter->new() } qr/Driver is required/, 'no driver given';
throws_ok { Catmandu::Exporter->new("ChunkyBacon") } qr/Can't load driver/, 'nonexistent driver given';
throws_ok { Catmandu::Exporter->new("Chunky::Bacon") } qr/Can't load driver/, 'nonexistent driver given';

