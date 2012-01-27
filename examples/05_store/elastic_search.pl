#!/usr/bin/env perl
#
# An example how to use the ElasticSearch interface
#
# We assume you have installed elasticsearch-0.17.6
# and started the server with the command:
#
# cd <ELASTIC_SEARCH>
# bin/elasticsearch
#
use Catmandu::Store::ElasticSearch;
use Catmandu::Exporter::YAML;
use Data::Dumper;

my $store = Catmandu::Store::ElasticSearch->new(index_name => 'catmandu');
my $exporter = Catmandu::Exporter::YAML->new();

# Add some data..
$store->bag->add({ name => 'Patrick' });
$store->bag->add({ name => 'Nicolas' });

# Important: commit the changes..
$store->bag->commit;

# Fetch the results...
$exporter->add_many($store->bag);

#$store->bag->delete_all;
#$store->bag->commit;

my $hits = $store->bag->search(query => 'name:Patrick');

print "Hits on 'name:Patrick'\n";
$exporter->add_many($hits);
