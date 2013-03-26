package Catmandu::Addable;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo::Role;

with 'Catmandu::Fixable';

requires 'add';

around add => sub {
    my ($orig, $self, $data) = @_;
    $data = $self->_fixer->fix($data) if $self->_fixer;
    $orig->($self, $data);
    $data;
};

sub add_many {
    my ($self, $many) = @_;

    if (is_hash_ref($many)) {
        $self->add($many);
        return 1;
    }

    if (is_array_ref($many)) {
        $self->add($_) for @$many;
        return scalar @$many;
    }

    if (is_invocant($many)) {
        $many = check_able($many, 'generator')->generator;
    }

    check_code_ref($many);

    my $data;
    my $n = 0;
    while (defined($data = $many->())) {
        $self->add($data);
        $n++;
    }
    $n;
}

sub commit {}

1;
