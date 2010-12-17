package Catmandu::Iterator;
# ABSTRACT Make an iteratable object by providing a closure
# VERSION
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

=head1 SYNOPSIS

    my $data = [1,2,3];
    my $iterator = Catmandu::Iterator->new(sub {
        my $callback = shift;
        for my $num (@$data) {
            $callback->($num);
        }
    });

    $iterator->each(sub {
        my $num = shift;
        print $num;
    });

