package Catmandu::Exporter::JSON;

use JSON qw(encode_json);
use Moose;

with 'Catmandu::Exporter';

sub dump {
    my ($self, $obj) = @_;

    my $f = $self->file;
    my $count = 0;

    if (ref $obj eq 'ARRAY') {
        $f->print(encode_json($obj));
        $count = scalar @$obj;
    }
    elsif (ref $obj eq 'HASH') {
        $f->print(encode_json($obj));
        $count = 1;
    }
    elsif (blessed($obj) && $obj->can('each')) {
        $f->print('[');
        $obj->each(sub {
            $f->print(',') if $count;
            $f->print(encode_json(shift));
            $count++;
        });
        $f->print(']');
    }
    else {
        confess "Can't export";
    }

    $count;
}

__PACKAGE__->meta->make_immutable;
no JSON;
no Moose;
__PACKAGE__;

