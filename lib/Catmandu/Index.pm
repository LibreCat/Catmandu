package Catmandu::Index;

use Any::Moose '::Role';

requires 'save';
requires 'find';
requires 'delete';

no Any::Moose '::Role';
__PACKAGE__;

