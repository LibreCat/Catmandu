#!/usr/bin/env perl
# Example BibText exporter

use Catmandu::Exporter::RIS;

my $exporter = Catmandu::Exporter::RIS->new();

$exporter->add({ 
   TY => 'JOUR' ,
   ID => '1981728' ,
   TI => 'The Portuguese inflected infinitive : an empirical approach' ,
   AU => ['Vanderschueren, Clara','Diependaele, Kevin'],
});

$exporter->add({ 
   TY => 'JOUR' ,
   ID => '1998138' ,
   TI => 'Teachers\' acceptance and use of an educational portal',
   AU => ['Pynoo, Bram','Tondeur, Jo','van Braak, Johan'],
});
