package Catmandu::Store;

use Any::Moose '::Role';

requires 'load';
requires 'each';
requires 'save';
requires 'delete';

no Any::Moose '::Role';
__PACKAGE__;

