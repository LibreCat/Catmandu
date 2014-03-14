package Catmandu::Importer::JSON;

use namespace::clean;
use Catmandu::Sane;
use JSON ();
use Moo;

my $RE_OBJ = qr'^[^{]+';

with 'Catmandu::Importer';

has lines => (is => 'ro', default => sub{0});
has json => (is => 'ro', lazy => 1, builder => '_build_json');

sub _build_json {
     JSON->new->utf8(0);
}

sub generator {
    my ($self) = @_;
    $self->lines ? sub {
        state $json = $self->json;
        state $fh   = $self->fh;
        if (defined(my $line = <$fh>)) {
            return $json->decode($line);
        }
        return;
    } : sub {
        state $json = $self->json;
        state $fh   = $self->fh;

        my $item = $json->incr_parse;
        return $item if $item;

        while (defined(my $line = <$fh>)) {
            my $item = $json->incr_parse($line);
            return $item if $item;
        }
        return;
    };
}

=head1 NAME

Catmandu::Importer::JSON - Package that imports JSON data

=head1 SYNOPSIS

    use Catmandu::Importer::JSON;

    my $importer = Catmandu::Importer::JSON->new(file => "/foo/bar.json");

    # read one or multiple concatenated JSON objects or arrays
    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

    With option 'lines' the JSON input needs to include one record per line:

    { "recordno": 1, "name": "Alpha" }
    { "recordno": 2, "name": "Beta" }
    { "recordno": 3, "name": "Gamma" }

=head1 METHODS

=head2 new( [ file => $filename | fh => $handle ] [ lines => 0|1 ] )

Create a new JSON importer for $filename or for file handle $handle. Use STDIN
by default. The option 'lines' can be enabled to enforce line-based parsing.

=head1 INHERITED METHODS

All methods of L<Catmandu::Importer> and by this L<Catmandu::Iterable> and
L<Catmandu::Fixable> are inherited. The Catmandu::Importer::JSON methods are
not idempotent: JSON streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Fixable>, L<JSON>

=cut

1;
