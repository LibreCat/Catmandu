package Catmandu::Cmd::OptIndex;

use Moose::Role;

has index => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'T',
    default => 'Simple',
    documentation => "The Catmandu::Index class to use. Defaults to Simple.",
);

has index_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 't',
    default => sub { +{} },
    documentation => "Pass params to the index constructor.",
);

no Moose::Role;
__PACKAGE__;

