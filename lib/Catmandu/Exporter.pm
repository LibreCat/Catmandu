package Catmandu::Exporter;

use Any::Moose '::Role';

requires 'dump';

has 'io' => (is => 'ro', required => 1);

__PACKAGE->meta->make_immutable;
no Any::Moose '::Role';
__PACKAGE__;

