#!/usr/bin/env perl
$|++;

use Catmandu::Importer::YAML;
use Catmandu::Importer::JSON;
use Catmandu::Importer::CSV;
use Catmandu::Importer::OAI;
use Catmandu::Importer::Atom;
use Catmandu::Importer::MARC;
use Data::Dumper;

# Importers are Catmandu classes to read data into an application.
# There are importers for JSON, YAML, CSV, Excel files but also
# Atom and OAI-PMH endpoints on the Internet.

# As example, lets read in a YAML file containing an array of values.
# We use the 'each' function to loop through all items
my $importer = Catmandu::Importer::YAML->new(file => "./test.yaml");

my $count = $importer->each(sub {
                my $obj = shift;
                print Dumper($obj);
});

print "Read: $count YAML items\n";

# The sample example can also be done for a JSON file...
my $importer = Catmandu::Importer::JSON->new(file => "./test.json");

my $count = $importer->each(sub {
                my $obj = shift;
                print Dumper($obj);
});

print "Read: $count JSON items\n";

# And for CSV files...
my $importer = Catmandu::Importer::CSV->new(file => "./test.csv");

my $count = $importer->each(sub {
                my $obj = shift;
                print Dumper($obj);
});

print "Read: $count CSV items\n";

# And MARC...
my $importer = Catmandu::Importer::MARC->new(file => "./test.xml", type => 'XML');

my $count = $importer->each(sub {
                my $obj = shift;
                print Dumper($obj);
});

print "Read: $count MARC items\n";

# We can even import data from OAI-PMH servers...
my $importer = Catmandu::Importer::OAI->new(url => 'http://arno.unimaas.nl/oai/dare.cgi');

my $count = $importer->take(10)->each(sub {
                my $obj = shift;
                print Dumper($obj);
});

print "Read sample of $count OAI items\n";
