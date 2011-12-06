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

1;
