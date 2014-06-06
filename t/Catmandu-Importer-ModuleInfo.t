#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::ModuleInfo';
    use_ok $pkg;
}

my $importer = $pkg->new(namespace => "Catmandu::Importer", max_depth => 1);

isa_ok $importer,$pkg;

ok($importer->any(sub { $_[0]->{name} eq $pkg }), "$pkg finds info about itself");

done_testing 3;
