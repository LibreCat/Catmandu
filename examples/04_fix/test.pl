#!/usr/bin/env perl

use Catmandu::Fix;
use Catmandu::Importer::YAML;
use Data::Dumper;
use subs qw(data_arr data_hash);

my $fixer;
my $importer;

# Fixes can be used to transform, map, enhance Catmandu objects. These
# methods are often used for data cleaning purposes.

# First start with a simple example we have an array of hashes with 
# job keys. For every name we want to uppercase the value.
print "[upcase('job')]\n";
$fixer = Catmandu::Fix->new(fixes => ['upcase("job")']);
print Dumper($fixer->fix(data_arr));

# We can do the same for a nested hash. E.g. updase the color inside fav.
$fixer = Catmandu::Fix->new(fixes => ['upcase("fav.color")']);
print "[upcase('fav.color')]\n";
print Dumper($fixer->fix(data_arr));

# Fixes can also be executed on hashes. E.g. we will try to upcase the
# job again for the second data set (see end of the script).
$fixer = Catmandu::Fix->new(fixes => ['upcase("list.2.fav.color")']);
print "[upcase('list.2.fav.color') [hash]]\n";
print Dumper($fixer->fix(data_hash));

# Fixes are most often used on iterator. E.g. we will import a YAML file
# and uppercase each job category found.
$fixer = Catmandu::Fix->new(fixes => ['upcase("job")']);
$importer = Catmandu::Importer::YAML->new(file => 'test.yaml');
print "[upcase('job') [< test.yaml]]\n";
$fixer->fix($importer)->each(sub {
   print Dumper($_[0]);
});

# The beauty of fixes is that it is a small DSL language. Fixes can be
# provides as an array, but we can also poin to a fox file. E.g. the
# file test.fix contains several fixes we can apply to the YAML file
$fixer = Catmandu::Fix->new(fixes => ['test.fix']);
$importer = Catmandu::Importer::YAML->new(file => 'test.yaml');
print "[upcase('job') [+test.fix < test.yaml]]\n";
$fixer->fix($importer)->each(sub {
   print Dumper($_[0]);
});


sub data_arr {
  [
	{ first => 'Charly' , last => 'Parker' , job => 'Artist' , fav => { color => "blue" }} ,
 	{ first => 'Albert' , last => 'Einstein' , job => 'Physicist' , fav => { color => "green" }} ,
 	{ first => 'Joseph' , last => 'Ratzinger' , job => 'Pope' , fav => { color => "white" }}
  ];
}

sub data_hash {
  { list => [
	{ first => 'Charly' , last => 'Parker' , job => 'Artist' , fav => { color => "blue" }} ,
 	{ first => 'Albert' , last => 'Einstein' , job => 'Physicist' , fav => { color => "green" }} ,
 	{ first => 'Joseph' , last => 'Ratzinger' , job => 'Pope' , fav => { color => "white" }}
    ]
  };
}
