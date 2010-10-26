package Catmandu::Store;

use Any::Moose '::Role';

requires 'load';
requires 'each';
requires 'save';
requires 'delete';

__PACKAGE->meta->make_immutable;
no Any::Moose '::Role';
__PACKAGE__;

