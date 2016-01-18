#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::XS ();
use Catmandu::Exporter::JSON;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::Multi';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];
my $file1 = "";
my $file2 = "";
my $exporter1 = Catmandu::Exporter::JSON->new(file => \$file1, line_delimited => 1);
my $exporter2 = Catmandu::Exporter::JSON->new(file => \$file2, line_delimited => 1);

my $exporter = $pkg->new(exporters => [
    $exporter1,
    $exporter2,
]);

isa_ok $exporter, $pkg;

$exporter->add_many($data);
$exporter->commit;

is $exporter1->count, 3;
is $exporter2->count, 3;
is $exporter->count, 3;
is_deeply $data, [ map { JSON::XS::decode_json($_) } split /[\r\n]+/, $file1 ];
is_deeply $data, [ map { JSON::XS::decode_json($_) } split /[\r\n]+/, $file2 ];

done_testing;
