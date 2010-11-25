package Catmandu::Exporter::JSON;

use Moose;

with 'Catmandu::Exporter';

has pretty => (
    is => 'ro' ,
    isa => 'Bool' ,
);

sub dump {
    my ($self, $obj) = @_;

    my $file = $self->file;
    my $n = 0;

    my $json = JSON->new->utf8(1)->pretty($self->pretty);

    if (ref $obj eq 'HASH') {
        $file->print($json->encode($obj));
        $n = 1;
    }
    elsif (ref $obj eq 'ARRAY') {
        $file->print($json->encode($obj));
        $n = @$obj;
    }
    elsif (blessed $obj and $obj->can('each')) {
        $file->print('[');
        $obj->each(sub {
            $file->print(',') if $n;
            $file->print($json->encode(shift));
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

