package Catmandu::Export::JSON;

use JSON qw(encode_json);
use Any::Moose;

with 'Catmandu::Export';

sub dump {
    my ($self, $obj) = @_;

    my $io = $self->io;
    my $count = 0;

    if (ref $obj eq 'ARRAY') {
        print $io encode_json($obj);
        $count = scalar @$obj;
    }
    elsif (ref $obj eq 'HASH') {
        print $io encode_json($obj);
        $count = 1;
    }
    elsif (blessed($obj) && $obj->can('each')) {
        print $io '[';
        $obj->each(sub {
            print $io ',' if $count;
            print $io encode_json(shift);
            $count++;
        });
        print $io ']';
    }
    else {
        confess "Can't export";
    }

    $count;
}

__PACKAGE->meta->make_immutable;
no JSON;
no Any::Moose;
__PACKAGE__;

