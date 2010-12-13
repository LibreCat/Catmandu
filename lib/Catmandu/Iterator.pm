package Catmandu::Iterator;

use namespace::autoclean;
use Moose;

with qw(Catmandu::Iterable);

has _each => (is => 'ro', isa => 'CodeRef', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $sub) = @_;
    { _each => $sub };
};

sub each {
    my ($self, $sub) = @_;
    $self->_each->($sub);
}

__PACKAGE__->meta->make_immutable;

1;

