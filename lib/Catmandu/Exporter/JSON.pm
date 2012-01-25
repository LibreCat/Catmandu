package Catmandu::Exporter::JSON;

use Catmandu::Sane;
use Moo;
use JSON ();

with 'Catmandu::Exporter';

has json => (is => 'ro', lazy => 1, builder => '_build_json');

sub _build_json {
     JSON->new->utf8(0);
}

sub add {
    my ($self, $data) = @_;
    my $fh = $self->fh;
    say $fh $self->json->encode($data);
}

1;
