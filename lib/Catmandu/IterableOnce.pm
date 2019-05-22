package Catmandu::IterableOnce;

use Catmandu::Sane;
use Moo::Role;

has exhausted => (is => 'rwp', default => sub {0});

around generator => sub {
    my ($orig, $self) = @_;
    return sub { }
        if $self->exhausted;
    $self->_set_exhausted(1);
    $orig->($self);
};

sub rewind { }

1;

__END__

=pod

=head1 NAME

Catmandu::IterableOnce - Role for iterable classes that can only iterate once

=head1 SYNOPSIS

    package MySingleUseIterator;
    use Moo;
    with 'Catmandu::Iterable';
    with 'Catmandu::Iterableonce';

    sub  generator {
        # ...
    }

=head1 SEE ALSO

L<Catmandu::Iterable>.

=cut
