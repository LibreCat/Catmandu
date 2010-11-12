package Catmandu::Importer;

use Moose::Role;

requires 'load';
requires 'each';

has 'file' => (is => 'ro', required => 1);

no Moose::Role;
__PACKAGE__;

