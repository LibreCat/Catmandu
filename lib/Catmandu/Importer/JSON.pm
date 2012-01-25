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

=head1 METHODS

=head2 new([file => $filename])

Create a new JSON importer for $filename. Use STDIN when no filename is given.

=head2 each(&callback)

The each method imports the data and executes the callback function for
each item imported. Returns the number of items imported or undef on 
failure.

=cut

1;
