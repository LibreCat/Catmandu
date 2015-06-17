#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use utf8;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::Text';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {_id => 1 , text => "Roses are red,\n"} ,
   {_id => 2 , text => "Violets are blue,\n"},
   {_id => 3 , text => "Sugar is sweet,\n"},
   {_id => 4 , text => "And so are you.\n"},
];

my $text = <<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.
EOF

my $importer = $pkg->new(file => \$text);

isa_ok $importer, $pkg;

my $arr = $importer->to_array;
is_deeply $arr, $data, 'checking correct import';

done_testing 4;