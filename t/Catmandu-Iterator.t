#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Iterator';
    use_ok $pkg;
}
require_ok $pkg;

my $g = sub { sub {} };

my $i = $pkg->new($g);
ok $i->does('Catmandu::Iterable');

done_testing 3;

