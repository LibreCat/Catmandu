#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok('Catmandu::Indexer'); }
require_ok('Catmandu::Indexer');

use Catmandu::Indexer;

throws_ok { Catmandu::Indexer->new() } qr/Driver is required/, 'no driver given';
throws_ok { Catmandu::Indexer->new("ChunkyBacon") } qr/Can't load driver/, 'nonexistent driver given';
throws_ok { Catmandu::Indexer->new("Chunky::Bacon") } qr/Can't load driver/, 'nonexistent driver given';
