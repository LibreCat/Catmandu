package Catmandu::Import::JSON;

use JSON ();
use File::Slurp ();
use Any::Moose;

with 'Catmandu::Import';

sub load {
    my ($self) = @_;

    my $io = $self->io;
    my $array_ref = JSON::decode_json(File::Slurp::slurp($io));
    if (ref $array_ref ne 'ARRAY') {
        confess "Can only import a JSON array";
    }
    $array_ref;
}

sub each {
    my ($self, $cb) = @_;

    my $array_ref = $self->load;
    my $count = 0;
    foreach my $obj (@$array_ref) {
        $cb->($obj);
        $count++;
    }
    $count;
}

__PACKAGE->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

