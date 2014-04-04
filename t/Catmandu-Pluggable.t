#!/usr/bin/env perl
package Catmandu::Plugin::Test;
use Moo::Role;

sub test {
	"ok";
}

package main;

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::Hash;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Pluggable';
    use_ok $pkg;
}
require_ok $pkg;

my $store = Catmandu::Store::Hash->new();
ok $store , 'new store';

my $bag = $store->bag->with_plugins('Test');
ok $bag , 'bag with Test plugin';
can_ok $bag , 'test';
is $bag->test , 'ok' , 'bag->test';
dies_ok { $store->bag->test } 'original bag doesnt have plugin';

done_testing 7;

