#!/usr/bin/env perl
# Example BibText exporter

use Catmandu::Exporter::BibTeX;

my $exporter = Catmandu::Exporter::BibTeX->new();

$exporter->add({ 
    _type => 'book',
    _citekey => '09-1290-2a0',
    title => 'Perl Programming',
    author => 'Wall, Larry'
});

$exporter->add({ 
    _type    => 'book',
    _citekey => '389-ajk0-1',
    title    => 'the Zen of {CSS} design',
    author   => ['Dave Shea','Molley E. Holzschlag'],
    isbn     => '0-321-30347-4'
});
