#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::YAML';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
    {name => 'Patrick',         age => '39'},
    {name => 'Nicolas',         age => '34'},
    {name => '村上 春樹', age => '65'},
];

my $yaml = <<EOF;
---
name: Patrick
age: 39
---
name: Nicolas
age: 34
---
name: 村上 春樹
age: 65

EOF

my $importer = $pkg->new(file => \$yaml);

isa_ok $importer, $pkg;

my $arr = $importer->to_array;
is_deeply $arr, $data, 'checking correct import';

is $arr->[2]->{name}, '村上 春樹', 'checking utf8 issues';

$importer = $pkg->new(file => 't/non_ascii.yaml');

is $importer->count, 1000, 'parsed non ascii file';

done_testing 6;

