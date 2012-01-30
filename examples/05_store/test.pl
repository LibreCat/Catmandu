#!/usr/bin/env perl

use Catmandu::Store::Hash;
use Catmandu::Exporter::YAML;

my $exporter = Catmandu::Exporter::YAML->new();

# In the following example we are going to make or items persistent
# using Catmandu:Store-s.

# Hash is an in-memory store that can be used for testing purposes
my $store = Catmandu::Store::Hash->new();

# Each store can have one or more 'bags'. These are compartments where
# to put your items. Lets add one item in the default bag....
print "Storing 'Patrick' in default bag\n";
$store->bag->add({
  name => 'Patrick'
});
&show_all($store->bag);

# And another in the bag 'testing'...
print "Storing 'Patrick' in 'testing' bag\n";
$store->bag('testing')->add({
  name => 'Nicolas'
});
print "\n ..the default contains this:\n\n";
&show_all($store->bag);
print "\n ..and the testing contains this:\n\n";
&show_all($store->bag('testing'));

# Notice that every stored items gets an '_id' identifier. We can
# generate them automatically or set them ourselves.
print "Storing 'Frank' with _if 'FNK01'\n";
$store->bag->add({
  _id  => 'FNK01', 
  name => 'Frank'
});
&show_all($store->bag);

# To read an item from a bag we need to provide the id...
print "Retrieving 'FNK01' from the bag\n";
my $item = $store->bag->get('FNK01');
&show_one($item);

# This id should also be used to delete an item from a bag...
print "Delete 'FNK01' from the bag\n";
$store->bag->delete('FNK01');
&show_all($store->bag);

# We can also delete all the items in one go...
print "Delete all the items from the bag\n";
$store->bag->delete_all;
&show_all($store->bag);

# Some Catmandu stores can also be used to search items. Lets
# add some more data and search the store

print "Adding fresh data to the store\n";
$store->bag->add({
  name => 'Patrick'
});
$store->bag->add({
  name => 'Nicolas'
});
$store->bag->add({
  name => 'Nicolas'
});
$store->bag->add({
  name => 'Frank'
});
&show_all($store->bag);

print "Searching for 'Nicolas'\n";
my $hits = $store->bag->search(query => 'Nicolas');
printf "Found: %d hits\n" , $hits->total;

$exporter->add_many($hits);

# A Search can also delete data. Lets delete all 'Nicolas' from the
# bag
print "Deleting 'Nicolas' from the bag\n";
$store->bag->delete_by_query(query => 'Nicolas');
&show_all($store->bag);

# Every bag is also an iterator...
$store->bag->each(sub {
   use Data::Dumper;
   print Dumper($_[0]);
});

sub show_one {
  my $item = shift;
  $exporter->add($item);
  print "\n";
}

sub show_all {
  my $bag = shift;
  $exporter->add_many($bag);
  print "\n";
}
