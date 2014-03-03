#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::CSV';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [{'a' => 'moose', b => '1'}, {'a' => 'pony', b => '2'}, {'a' => 'shrimp', b => '3'}];
my $file = "";

my $exporter = $pkg->new(file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

my $csv = <<EOF;
a,b
moose,1
pony,2
shrimp,3
EOF

is($file, $csv, "CSV strings ok");

is($exporter->count,3, "Count ok");

done_testing 5;
