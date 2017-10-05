package Catmandu::Counter;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Moo::Role;
use namespace::clean;

has count => (is => 'rwp', default => sub {0});

sub inc_count {
    my $self = $_[0];
    $self->_set_count($self->count + 1);
}

sub dec_count {
    my $self = $_[0];
    $self->count ? $self->_set_count($self->count - 1) : 0;
}

sub reset_count {
    my $self = $_[0];
    $self->_set_count(0);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Counter - A Base class for modules who need to count things

=head1 SYNOPSIS

    package MyPackage;

    use Moo;

    with 'Catmandu::Counter';

    sub calculate {
        my ($self) = @_;
        $self->inc_count;
        #...do stuff
    }

    package main;

    my $x = MyPackage->new;

    $x->calculate;
    $x->calculate;
    $x->calculate;

    print "Executed calculate %d times\n" , $x->count;

=head1 ATTRIBUTES

=head2 count

The current value of the counter.

=head1 METHODS

=head2 inc_count()

=head2 inc_count(NUMBER)

Increment the counter.

=head2 dec_count()

=head2 dec_count(NUMBER)

Decrement the counter.

=head2 reset_count()

Reset the counter to zero.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
