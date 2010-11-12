package Catmandu::Importer::JSON;

use Moose;
use JSON ();
use File::Slurp ();

with 'Catmandu::Importer';

sub load {
    my ($self) = @_;

    my $array_ref = JSON::decode_json(File::Slurp::slurp($self->file));
    if (ref $array_ref ne 'ARRAY') {
        confess "Can only import a JSON array";
    }
    $array_ref;
}

sub each {
    my ($self, $sub) = @_;

    my $array_ref = $self->load;
    my $count = 0;
    foreach my $obj (@$array_ref) {
        $sub->($obj);
        $count++;
    }
    $count;
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

