#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::CSV';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {name=>'Patrick',age=>'39'},
   {name=>'Nicolas',age=>'34'},
];

my $csv = <<EOF;
"name","age"
"Patrick","39"
"Nicolas","34"
EOF

my $importer = $pkg->new(file => \$csv);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data;

done_testing 4;

