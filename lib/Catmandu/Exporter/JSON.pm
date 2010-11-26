package Catmandu::Exporter::JSON;

use Moose;
use JSON ();

with 'Catmandu::Exporter';

has pretty => (
    is => 'ro' ,
    isa => 'Bool' ,
    default => 0,
);

sub dump {
    my ($self, $obj) = @_;

    my $json = JSON->new->utf8(1)->pretty($self->pretty);
    my $file = $self->file;
    my $n = 0;

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
            $file->print($json->encode($_[0]));
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
no Moose;
__PACKAGE__;

