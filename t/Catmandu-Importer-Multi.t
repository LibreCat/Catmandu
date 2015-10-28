#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::Mock;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::Multi';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {n => 0},
   {n => 1},
   {n => 2},
];

my $importer = $pkg->new(importers => [
    Catmandu::Importer::Mock->new(size => 3),
    Catmandu::Importer::Mock->new(size => 3),
]);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, [@$data, @$data];

done_testing;

