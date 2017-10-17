package Catmandu::Path;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo::Role;

has path => (is => 'ro', required => 1);

requires 'getter';
requires 'setter';
requires 'creator';
requires 'updater';
requires 'deleter';

1;
