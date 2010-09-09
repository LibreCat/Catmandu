#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Exporter'; }
require_ok 'Catmandu::Exporter';

throws_ok { Catmandu::Exporter->open() } qr/Export format missing/, 'no format given';
throws_ok { Catmandu::Exporter->open("ChunkyBacon") } qr/Failed to load exporter/, 'nonexisting format given';

