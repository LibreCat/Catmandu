package Catmandu::Importer::Mock;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

has size => (is => 'ro');

sub generator {
    my ($self) = @_;
    my $n = 0;
    sub {
	   return if defined $self->size && $n == $self->size;
	   return { n => $n++ };
    };
}

=head1 NAME

Catmandu::Importer::Mock - Mock importer used for testing purposes

=head1 SYNOPSIS

    use Catmandu::Importer::Mock;

    my $importer = Catmandu::Importer::Mock->new();

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new(size => $n)

Create a new Mock importer. Optionally provide a size parameter.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
