#!/usr/bin/env perl
#
# An example how to use the DBI interface
#
use Catmandu::Store::DBI;
use Catmandu::Exporter::YAML;

my $store = Catmandu::Store::DBI->new(data_source => 'DBI:mysql:database=test');

my $exporter = Catmandu::Exporter::YAML->new();

$store->bag->add({
   name => 'Patrick'
});

$store->bag->add({
   name => 'Nicolas'
});

$exporter->add_many($store->bag);

$store->bag->delete_all;
