#!/usr/bin/env perl
#
# An example how to use the Solr interface
#
# We assume you have installed the Solr software
# and edited the example Solr scheme to include
# the required '_id' and '_bag' fields used
# in Catmandu.
#
# In example/solr/conf/schema.xml line 500 delete the 'id' and add:
#
#  <field name="_id" type="string" indexed="true" stored="true" required="true" />
#  <field name="_bag" type="string" indexed="true" stored="true" required="true" />
#
# and chanege uniqueKey to:
#
# <uniqueKey>_id</uniqueKey>
#
# and started the server with:
#
# java -jar start.jar
#
use Catmandu::Store::Solr;
use Catmandu::Exporter::YAML;

my $store = Catmandu::Store::Solr->new(url => 'http://localhost:8983/solr');
my $exporter = Catmandu::Exporter::YAML->new();

# Add some data..
$store->bag->add({ name => 'Patrick' });
$store->bag->add({ name => 'Nicolas' });

# Important: commit the changes..
$store->bag->commit;

# Fetch the result...
$exporter->add_many($store->bag);

# $store->bag->delete_all;

my $hits = $store->bag->search(query => 'name:Patrick');

print "Hits on 'name:Patrick'\n";
$exporter->add_many($hits);
