#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('Catmandu::Indexer::Mock'); }
require_ok('Catmandu::Indexer::Mock');

use Catmandu::Indexer::Mock;

our $list = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];

package Each;
sub new { bless {}, shift }

sub each {
    my ($self, $sub) = @_;
    foreach my $obj (@$list) {
        $sub->($obj);
    }
}

package main;

my $indexer = Catmandu::Indexer::Mock->new();

ok(defined $indexer, 'new');
is($indexer->index({ id => 1}), 1,'index(hashref)');
is($indexer->index([{ id => 1} , { id => 2}]), 2,'index(hashref)');
is($indexer->index(Each->new), 3,'index(something_that_does_each)');


