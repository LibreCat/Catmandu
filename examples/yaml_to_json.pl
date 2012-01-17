#!/usr/bin/env perl

use Catmandu::Importer::YAML;
use Catmandu::Exporter::JSON;

my $in  = shift or die "usage: $PROGRAM_NAME yaml-file json-file";
my $out = shift or die "usage: $PROGRAM_NAME yaml-file json-file";

my $importer = Catmandu::Importer::YAML->new(file => $in);
my $exporter = Catmandu::Exporter::JSON->new(file => $out);

$exporter->add_many($importer);
