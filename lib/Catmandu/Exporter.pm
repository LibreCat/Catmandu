package Catmandu::Exporter;

use Moose::Role;

requires 'dump';

has 'file' => (is => 'ro', required => 1);

no Moose::Role;
__PACKAGE__;

