package Catmandu::Cmd::OptImporter;

use Moose::Role;

has importer => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'I',
    default => 'JSON',
    documentation => "The Catmandu::Importer class to use. Defaults to JSON.",
);

has importer_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'i',
    default => sub { +{} },
    predicate => 'has_importer_arg',
    documentation => "Pass params to the importer constructor.",
);

no Moose::Role;
__PACKAGE__;

