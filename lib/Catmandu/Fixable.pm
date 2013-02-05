package Catmandu::Fixable;

use Catmandu::Sane;
use Moo::Role;
use Catmandu::Util qw(is_instance);
use Catmandu;

has _fixer => (
    is => 'ro',
    init_arg => 'fix',
    coerce => sub {
        is_instance($_[0]) ? $_[0] : Catmandu->fixer($_[0]);
    },
);

1;
