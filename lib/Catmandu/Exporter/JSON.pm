package Catmandu::Exporter::JSON;

use Moose;

with 'Catmandu::Exporter';

use JSON qw(encode_json);

sub dump {
    my ($self, $obj) = @_;

    my $file = $self->file;
    my $n = 0;

    if (ref $obj eq 'HASH') {
        $file->print(encode_json($obj));
        $n = 1;
    }
    elsif (ref $obj eq 'ARRAY') {
        $file->print(encode_json($obj));
        $n = @$obj;
    }
    elsif (blessed $obj and $obj->can('each')) {
        $file->print('[');
        $obj->each(sub {
            $file->print(',') if $n;
            $file->print(encode_json(shift));
            $n++;
        });
        $file->print(']');
    }
    else {
        confess "Can't export";
    }

    $n;
}

__PACKAGE__->meta->make_immutable;
no JSON;
no Moose;
__PACKAGE__;

