package Catmandu::Importer::JSON;

use 5.010;
use Moose;

with 'Catmandu::Importer';

use JSON qw(decode_json);

sub each {
    my ($self, $sub) = @_;

    my $obj;

    if ($self->file->is_string) {
        $obj = decode_json ${$self->file->string_ref};
    } else {
        $obj = decode_json $self->file->slurp;
    }

    given (ref $obj) {
        when ('ARRAY') {
            my $n = 0;
            for my $o (@$obj) {
                $sub->($o);
                $n++;
            }
            return $n;
        }
        when ('HASH') {
            $sub->($obj);
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

