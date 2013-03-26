package Catmandu::Fixable;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_instance);
use Catmandu;
use Moo::Role;

has _fixer => (
    is => 'ro',
    init_arg => 'fix',
    coerce => sub {
        is_instance($_[0]) ? $_[0] : Catmandu->fixer($_[0]);
    },
);

1;
