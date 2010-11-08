package Catmandu::Importer;

use Any::Moose '::Role';

requires 'load';
requires 'each';

has 'file' => (is => 'ro', required => 1);

no Any::Moose '::Role';
__PACKAGE__;

