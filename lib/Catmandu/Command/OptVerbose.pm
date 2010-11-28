package Catmandu::Command::OptVerbose;

use Moose::Role;

has verbose => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    cmd_aliases => 'v',
    documentation => "Verbose output.",
);

no Moose::Role;
__PACKAGE__;

