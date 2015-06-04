package Catmandu::Importer::Mock;

use namespace::clean;
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

1;
__END__

=head1 NAME

Catmandu::Importer::Mock - Mock importer used for testing purposes

=head1 SYNOPSIS

    use Catmandu::Importer::Mock;

    my $importer = Catmandu::Importer::Mock->new();

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 CONFIGURATION

=over

=item file

=item fh

=item encoding

=item fix

Default options of L<Catmandu::Importer>

=item size

Number of items. If not set, an endless stream is imported.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
