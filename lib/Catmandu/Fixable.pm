package Catmandu::Fixable;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Fix;
use Moo::Role;

has fix => (
    is => 'ro',
    coerce => sub {
        is_array_ref($_[0])
            ? Catmandu::Fix->new(fixes => $_[0])
            : $_[0];
    },
);

1;
