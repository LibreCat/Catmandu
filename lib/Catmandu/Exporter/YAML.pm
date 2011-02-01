package Catmandu::Exporter::YAML;
# ABSTRACT: Streaming YAML exporter
# VERSION
use Moose;
use IO::YAML;

with qw(
    Catmandu::FileWriter
    Catmandu::Exporter
);

sub dump {
    my ($self, $obj) = @_;

    my $file = IO::YAML->new($self->file, auto_terminate => 1);

    if (ref $obj eq 'ARRAY') {
        $file->print($_) for @$obj;
        return scalar @$obj;
    }
    if (ref $obj eq 'HASH') {
        $file->print($obj);
        return 1;
    }
    if (blessed $obj and $obj->can('each')) {
        return $obj->each(sub {
            $file->print($_[0]);
        });
    }

    confess "Can't export object";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

