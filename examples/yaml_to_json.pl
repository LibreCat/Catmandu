#!/usr/bin/env perl

use Catmandu::Importer::YAML;
use Catmandu::Exporter::JSON;

my $in  = shift;
my $out = shift;

my $importer = Catmandu::Importer::YAML->new(file => $in);
my $exporter = Catmandu::Exporter::JSON->new(file => $out, pretty => 1);

$exporter->add($importer);
