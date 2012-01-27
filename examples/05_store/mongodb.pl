#!/usr/bin/env perl
#
# An example how to use the MongoDB interface
#
# We assume you have installed the MongoDB software
# and created a data directory (e.g. /data/db)
#
# mkdir /data/db
#
# And started the database with
#
# cd <MONGO_DB>
# bin/mongod --dbpath /data/db
#
use Catmandu::Store::MongoDB;
use Catmandu::Exporter::YAML;

my $store = Catmandu::Store::MongoDB->new(database_name => 'test');
my $exporter = Catmandu::Exporter::YAML->new();

$store->bag->add({ name => 'Patrick' });

$store->bag->add({ name => 'Nicolas' });

$exporter->add_many($store->bag);

$store->bag->delete_all;
