#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::TSV';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {name=>'Patrick',age=>'44'},
   {name=>'Nicolas',age=>'39'},
];

my $tsv = <<EOF;
name\tage
Patrick\t44
Nicolas\t39
EOF

my $importer = $pkg->new(file => \$tsv);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data;

$data = [
   {0=>'Patrick',1=>'44'},
   {0=>'Nicolas',1=>'39'},
];

$tsv = <<EOF;
Patrick\t44
Nicolas\t39
EOF

$importer = $pkg->new(file => \$tsv, header => 0);

is_deeply $importer->to_array, $data;

$tsv = <<EOF;
Patrick 44
Nicolas 39
EOF

$importer = $pkg->new(file => \$tsv, header => 0, sep_char => ' ');

is_deeply $importer->to_array, $data;

done_testing;
