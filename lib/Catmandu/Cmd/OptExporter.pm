package Catmandu::Cmd::OptExporter;

use Moose::Role;

has exporter => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'O',
    default => 'JSON',
    documentation => "The Catmandu::Exporter class to use. Defaults to JSON.",
);

has exporter_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'o',
    default => sub { +{} },
    predicate => 'has_exporter_arg',
    documentation => "Pass params to the exporter constructor.",
);

no Moose::Role;
__PACKAGE__;

