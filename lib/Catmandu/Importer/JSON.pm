package Catmandu::Importer::JSON;

use Catmandu::Sane;
use Moo;
use JSON ();

my $RE_OBJ = qr'^[^{]+';

with 'Catmandu::Importer';

has json => (is => 'ro', lazy => 1, builder => '_build_json');

sub _build_json {
     JSON->new->utf8(0);
}

sub generator {
    my ($self) = @_;
    sub {
        state $json = $self->json;
        state $fh   = $self->fh;
        if (defined(my $line = <$fh>)) {
            return $json->decode($line);
        }
        return;
    };
}

=head1 NAME

Catmandu::Importer::JSON - Package that imports JSON data

=head1 SYNOPSIS

    use Catmandu::Importer::JSON;

    my $importer = Catmandu::Importer::JSON->new(file => "/foo/bar.json");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

    The JSON input file needs to include one record per line:

    { "recordno": 1, "name": "Alpha" }
    { "recordno": 2, "name": "Beta" }
    { "recordno": 3, "name": "Gamma" }

=head1 METHODS

=head2 new([file => $filename])

Create a new JSON importer for $filename. Use STDIN when no filename is given.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::JSON methods are not idempotent: JSON streams can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
