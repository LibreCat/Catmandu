package Catmandu::Importer;

use Any::Moose '::Role';

requires 'load';
requires 'each';

has 'io' => (is => 'ro', required => 1);

__PACKAGE->meta->make_immutable;
no Any::Moose '::Role';
__PACKAGE__;

