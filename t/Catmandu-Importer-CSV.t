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

my $data
    = [{name => 'Patrick', age => '39'}, {name => 'Nicolas', age => '34'},];

my $csv = <<EOF;
"name","age"
"Patrick","39"
"Nicolas","34"
EOF

my $importer = $pkg->new(file => \$csv);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data, 'CSV with header.';

$csv = <<EOF;
\xEF\xBB\xBF"name","age"
"Patrick","39"
"Nicolas","34"
EOF

$importer = $pkg->new(file => \$csv);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data, 'CSV with header, BOM.';

$data = [{0 => 'Patrick', 1 => '39'}, {0 => 'Nicolas', 1 => '34'},];

$csv = <<EOF;
"Patrick","39"
"Nicolas","34"
EOF

$importer = $pkg->new(file => \$csv, header => 0);

is_deeply $importer->to_array, $data, 'CSV without header.';

$data = [{name => 'Nicolas', age => '34'},];

$csv = <<EOF;
"name"	"age"
"Nicolas"	"34"
EOF

$importer = $pkg->new(file => \$csv, sep_char => '\t');

is_deeply $importer->to_array, $data, 'CSV with header, separator is tab.';

$csv = <<EOF;
\xEF\xBB\xBF"name"	"age"
"Nicolas"	"34"
EOF

$importer = $pkg->new(file => \$csv, sep_char => '\t');

is_deeply $importer->to_array, $data, 'CSV with header, separator is tab, BOM.';

done_testing;

