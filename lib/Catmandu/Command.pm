package Catmandu::Command;

use Moose::Role;

with 'MooseX::Getopt';

requires 'run';

no Moose::Role;
__PACKAGE__;

