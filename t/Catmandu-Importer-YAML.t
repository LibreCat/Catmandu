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
    $pkg = 'Catmandu::Importer::YAML';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {name=>'Patrick',age=>'39'},
   {name=>'Nicolas',age=>'34'},
];

my $yaml = <<EOF;
---
name: Patrick
age: 39
---
name: Nicolas
age: 34

EOF

my $importer = $pkg->new(file => \$yaml);

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data;

done_testing 4;

