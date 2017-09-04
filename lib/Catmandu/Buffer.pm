package Catmandu::Buffer;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Moo::Role;
use namespace::clean;

has buffer_size => (is => 'ro', lazy => 1, builder => 'default_buffer_size');
has buffer => (is => 'rwp', lazy => 1, default => sub {[]});

sub default_buffer_size {100}

sub clear_buffer {
    $_[0]->_set_buffer([]);
}

sub buffer_used {
    scalar @{$_[0]->buffer};
}

sub buffer_is_full {
    my $self = $_[0];
    $self->buffer_used >= $self->buffer_size ? 1 : 0;
}

sub buffer_add {
    my $buffer = shift->buffer;
    push @$buffer, @_;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Buffer - A base class for modules that need an array buffer

=head1 SYNOPSIS

    package MyPackage;

    use Moo;

    with 'Catmandu::Buffer';

    # Print only when the buffer is full...
    sub print {
        my ($self,$str) = @_;

        if ($self->buffer_is_full) {
           print join "\n" , @{ $self->buffer };

           $self->clear_buffer; 
        } 

        $self->buffer_add($str);
    }

    package main;

    my $x = MyPackage->new;

    for (my $i = 0 ; $i < 1000 ; $i++) {
        $x->print($x);
    }

=head1 ATTRIBUTES

=head2 buffer

A ARRAY reference to the content of the buffer.

=head2 buffer_size(MAX)

The maximum size of a buffer.

=head1 METHODS

=head2 clear_buffer()

Empty the buffer.

=head2 buffer_used()

Returns a true value when there is content in the buffer.

=head2 buffer_is_full()

Returns a true value when the buffer has reached its maximum capacity.

=head2 buffer_add($x)

Adds $x to the buffer.

=head1 SEE ALSO

L<Catmandu::Solr::Bag>

=cut
