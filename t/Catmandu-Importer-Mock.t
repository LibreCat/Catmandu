#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::Mock';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {n => 0},
   {n => 1},
   {n => 2},
];

my $importer = $pkg->new(size => 3);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data, "Data structure ok";

done_testing 4;

