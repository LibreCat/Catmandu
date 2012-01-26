#!/usr/bin/env perl

use Catmandu::Importer::Mock;
use Data::Dumper;

# In this Perl script we are going to experiment a bit with the
# iterable features of Catmandu.

# Mock is a test iterator that generates hashes in memory.
my $it = Catmandu::Importer::Mock->new(size => 10);

# To return all items in the iterator as an array we use the to_array method
my $ref =  $it->to_array;

print "[to_array]\n";
print Dumper($ref);
printf "Mock contains %d items\n" , int @$ref;

# With count we can check the number of items in an iterator. 
my $count = $it->count;
print "[count]\n";
printf "Mock contains %d items\n" , $count;

# Use the slice command to loop over a part of the items. E.g. 
# read all the items from offset 3 with length 2.
# Slice returns an iterator btw.
print "[slice]\n";
print Dumper($it->slice(3,2)->to_array);

# With each you can loop over all the items in an iterator
print "[each]\n";
$it->each(sub {
   my $hash = shift;
   printf "My n is %d\n" , $hash->{n};
});

# The tap method is like the Unix 'tee' you can split up an interator 
# into two parts and iterate over both
print "[tap]\n";
$it->tap(\&logme)->each(sub {
   my $hash = shift;
   printf "My n is %d\n" , $hash->{n};
});

# With the any method we can check of the iterator contains at least
# one item for which a callback returns true. Lets test if the
# Mock contains an n > 4
print "[any]\n";
my $answer = $it->any(sub { shift->{n} > 4});
printf "Iterator contains n > 4 = %s\n" , $answer ? 'TRUE' : 'FALSE';

# When you need to check if there at least 2 items form which a 
# callback return true, use the many method. Lets test if there
# are at least 2 item in Mock with n > 8 (not)
print "[many]\n";
my $answer = $it->many(sub { shift->{n} > 8});
printf "Iterator contains n > 8 = %s\n" , $answer ? 'TRUE' : 'FALSE';

# When you need to check if /all/ the items in Mock match some
# condition use the all method. Lets test if all the items in
# Mock are numeric
print "[all]\n";
my $answer = $it->all(sub { shift->{n} =~ /^\d+$/});
printf "Iterator contains only digits = %s\n" , $answer ? 'TRUE' : 'FALSE';

# With the method map you can transform items of an iterator
# in a new iterator with new values. Lets create an iterator
# which doubles all values of 'n' and adds a time field.
print "[map]\n";
my $ret = $it->map(sub {
     my $hash = shift;
     { n => $hash->{n} * 2 , 'time' => time }
})->to_array;
print Dumper($ret);

# The method reduce is like map but you add a callback function
# to summerize all results. The result is the summary of all
# mappings. Lets double all the values of 'n' and compute the
# sum.
print "[reduce]\n";
my $result = $it->reduce(0,sub {
     my $prev = shift;
     my $this = shift->{n} * 2;
     $prev + $this;
});
printf "SUM [ Iterator * 2] = %d\n" , $result;

# The first method is easy: return the first item in an iterator.
print "[first]\n";
my $first = $it->first;
printf "The first item has n = %d\n" , $first->{n};

# The rest method returns an iterator for everything except the
# first.
print "[rest]\n";
$it->rest->each(sub { printf "And then we have n = %d\n", shift->{n} });

# The take methiod can be used to grep some items from the top of the
# Iterator. Lets read the first 5.
print "[take]\n";
$it->take(5)->each(sub { printf "And then we have n = %d\n", shift->{n} });

# The detect method returns the first item for which a callback is true.
# Lets grep the first item with n > 5.
print "[detect]\n";
my $result = $it->detect(sub {
    shift->{n} > 5;
});
printf Dumper($result);

# With the select method you can return an iterator for all the values 
# where a callback is true. Lets grep all the items where n > 5.
print "[select]\n";
print Dumper($it->select(sub { shift->{n} > 5})->to_array);

# The reject method is just the opposite of select. Return an iterator
# for all items where the callback is false. Lets grep all the items
# where n is not > 5.
print "[reject]\n";
print Dumper($it->reject(sub { shift->{n} > 5})->to_array);

# Most of the LibreCat implementations use HASH-es as items. With the
# pluck method you can return an iterator of values these hash given
# an key. Lets create an iterator for all the 'n' values in the Mock
# iterator.
print "[pluck]\n";
print Dumper($it->pluck('n')->to_array);

# The includes can be used to test of an item is already contained in
# the Iterar. Lets test if a hash { n => 5 } is available in Mock.
print "[includes]\n";
my $result = $it->includes({ n => 42 });
printf "{n => 42} is in Mock = %s\n" , $result ? 'TRUE' : 'FALSE';

# The group method can be used to split an iterator in groups of
# a specified size. Lets create a Mock of 100 objects and split
# the iterator in parts of 10
print "[group]\n";
my $it = Catmandu::Importer::Mock->new(size => 100);
my $groupnr  = 1;
$it->group(10)->each(sub {
    my $it = shift;
    printf "group %d has %d items\n" , $groupnr++ , $it->count;
});

sub logme {
  my $obj = shift;
  my $date = localtime time;
  print "$date : LOG : reading $obj\n";
}
