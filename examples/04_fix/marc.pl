#!/usr/bin/env perl
#
use Catmandu::Fix;
use Catmandu::Importer::MARC;
use Data::Dumper;

my $fixer = Catmandu::Fix->new(fixes => ['marc.fix']);
my $it    = Catmandu::Importer::MARC->new(file => 'marc.txt', type => 'ALEPHSEQ');

$fixer->fix($it)->each(sub {
   print Dumper($_[0]);
});
