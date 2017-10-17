package Catmandu::Fix::Builder;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Catmandu::Fix;
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

requires '_build_fixer';

has fixer => (is => 'lazy');

sub fix {
    $_[0]->fixer->($_[1]);
    $_[1];
}

1;
