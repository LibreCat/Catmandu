#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::JSON';
    use_ok $pkg;
}
require_ok $pkg;

sub test_import(@) { ##no critic
    my $importer = Catmandu::Importer::JSON->new(%{$_[0]});
    isa_ok $importer, 'Catmandu::Importer::JSON';
    if ($_[1]) {
        is_deeply $importer->to_array, $_[1];
    } else {
        dies_ok { $importer->to_array };
    }
}

my $data = [
   {name=>'Patrick',age=>'39'},
   [3,2,1],
   {foo=>JSON::true,bar=>JSON::false}, # TODO: convert to 0/1?
];

my $json_lines = <<EOF;
{"name":"Patrick","age":"39"}
[3,2,1]
{"foo":true,"bar":false}
EOF

my $json_multilines = <<EOF;
{"name":"Patrick","age":"39"} [3,2,1
]
{
  "foo":true,
  "bar":false
}
EOF

test_import { file => \$json_lines }, $data;
test_import { file => \$json_lines, lines => 1 }, $data;
test_import { file => \$json_multilines }, $data;
test_import { file => \$json_multilines, lines => 1 }, undef;

done_testing 5;
