package Catmandu::Index;

use Any::Moose '::Role';

requires 'save';
requires 'find';
requires 'delete';
requires 'commit';

no Any::Moose '::Role';
__PACKAGE__;

