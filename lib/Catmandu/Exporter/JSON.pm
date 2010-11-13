package Catmandu::Exporter::JSON;

use JSON qw(encode_json);
use Moose;

with 'Catmandu::Exporter';

sub dump {
    my ($self, $obj) = @_;

    my $f = $self->file;
    my $count = 0;

    if (ref $obj eq 'ARRAY') {
        print $f encode_json($obj);
        $count = scalar @$obj;
    }
    elsif (ref $obj eq 'HASH') {
        print $f encode_json($obj);
        $count = 1;
    }
    elsif (blessed($obj) && $obj->can('each')) {
        print $f '[';
        $obj->each(sub {
            print $f ',' if $count;
            print $f encode_json(shift);
            $count++;
        });
        print $f ']';
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

