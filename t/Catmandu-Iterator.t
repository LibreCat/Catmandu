#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::ConfigData;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    #unless (Catmandu::ConfigData->feature('')) {
    #    plan skip_all => 'feature disabled';
    #}
    $pkg = 'Catmandu::Iterator';
    use_ok $pkg;
}
require_ok $pkg;

my $g = sub { sub {} };

my $i = $pkg->new($g);
is $i->generator, $g;
ok $i->does('Catmandu::Iterable');

done_testing 4;

