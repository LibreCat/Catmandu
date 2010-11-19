package Catmandu::Importer::JSON;

use 5.010;
use Moose;
use JSON ();

with 'Catmandu::Importer';

sub each {
    my ($self, $sub) = @_;

    my $ref = JSON::decode_json($self->file->slurp);
    given (ref $ref) {
        when ('ARRAY') {
            my $count = 0;
            foreach my $obj (@$ref) {
                $sub->($obj);
                $count++;
            }
            return $count;
        }
        when ('HASH') {
            $sub->($ref);
            return 1;
        }
        default {
            confess "Can only import a JSON hash or array of hashes";
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

