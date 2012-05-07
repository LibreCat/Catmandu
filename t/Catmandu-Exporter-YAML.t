#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use YAML::Any ();

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::YAML';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];
my $file = "";

my $exporter = $pkg->new(file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;
is_deeply $data, [ YAML::Any::Load($file) ];

done_testing 4;

