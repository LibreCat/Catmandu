package Catmandu::Fix::Namespace;

use Catmandu::Sane;

our $VERSION = '1.10_03';

use Moo::Role;
use namespace::clean;

requires 'load';

has name => (is => 'ro', required => 1);

1;
