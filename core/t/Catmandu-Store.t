#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Store'; }
require_ok 'Catmandu::Store';

throws_ok { Catmandu::Store->new() } qr/Driver is required/, 'no driver given';
throws_ok { Catmandu::Store->new("ChunkyBacon") } qr/Can't load driver/, 'nonexistent driver given';
throws_ok { Catmandu::Store->new("Chunky::Bacon") } qr/Can't load driver/, 'nonexistent driver given';

use_ok 'Catmandu::Store', qw(driver done);
use_ok 'Catmandu::Store', qw(load save delete each);
