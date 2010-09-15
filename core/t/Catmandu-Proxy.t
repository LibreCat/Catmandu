#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok 'Catmandu::Proxy'; }
require_ok 'Catmandu::Proxy';

package TestProxy;

use Catmandu::Proxy;
use Test::Exception;

proxy 'foo', 'bar';
throws_ok { proxy } qr/can only be declared once/, 'proxy only once';

package main;

can_ok 'TestProxy', qw(driver done);
can_ok 'TestProxy', qw(foo bar);
