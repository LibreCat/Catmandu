package Catmandu::Importer::Text;

use namespace::clean;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

sub generator {
    my ($self) = @_;
    sub {
        state $fh = $self->fh;
        state $cnt = 0;
        state $line;

        defined($line = <$fh>) ? { _id => ++$cnt , text => $line } : undef;
    };
}

1;
__END__

=head1 NAME

Catmandu::Importer::Text - Package that imports textual data

=head1 SYNOPSIS

    use Catmandu::Importer::Text;

    my $importer = Catmandu::Importer::text->new(file => "/foo/bar.yaml");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        
        printf "line %d: text: %s" , $hashref->{_id} , $hashref->{text};  
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

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::YAML methods are not idempotent: YAML feeds
can only be read once.

=head1 SEE ALSO

L<Catmandu::Exporter::Text>

=cut
