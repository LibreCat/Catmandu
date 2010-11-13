package Catmandu::Index;

use Moose::Role;

requires 'save';
requires 'find';
requires 'delete';
requires 'commit';

no Moose::Role;
__PACKAGE__;

