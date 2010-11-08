package Catmandu::Exporter;

use Any::Moose '::Role';

requires 'dump';

has 'file' => (is => 'ro', required => 1);

no Any::Moose '::Role';
__PACKAGE__;

