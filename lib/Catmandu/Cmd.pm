package Catmandu::Cmd;

use Moose::Role;

with 'MooseX::Getopt::Dashes';

requires 'run';

no Moose::Role;
__PACKAGE__;

