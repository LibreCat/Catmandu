use MooseX::Declare;

class Catmandu::Importer::JSON with Catmandu::Importer {
    use 5.010;
    use JSON qw(decode_json);

    method each (CodeRef $sub) {
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
}

1;

