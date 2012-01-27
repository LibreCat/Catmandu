#!/usr/bin/env perl
# Example XLS exporter

use Catmandu::Exporter::XLS;

my $exporter = Catmandu::Exporter::XLS->new(header => 1);

$exporter->fields([qw(_type _citekey title author isbn)]);

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
