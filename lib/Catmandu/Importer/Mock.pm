package Catmandu::Importer::Mock;

use Catmandu::Sane;

our $VERSION = '1.0603';

use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has size => (is => 'ro');

sub generator {
    my ($self) = @_;
    my $n = 0;
    sub {
        return if defined $self->size && $n == $self->size;
        return {n => $n++};
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::Mock - Mock importer used for testing purposes

=head1 SYNOPSIS

    use Catmandu;

    my $importer = Catmandu->importer('Mock');

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item size

Number of items. If not set, an endless stream is imported.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Exporter::Null>

=cut
