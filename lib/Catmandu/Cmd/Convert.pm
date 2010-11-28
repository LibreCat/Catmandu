package Catmandu::Cmd::Convert;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with qw(
    Catmandu::Command
    Catmandu::Command::OptImporter
    Catmandu::Command::OptExporter
);

sub _usage_format {
    "usage: %c %o [file] [file]";
}

sub BUILD {
    my $self = shift;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);

    if (my $arg = shift @{$self->extra_argv}) {
        $self->importer_arg->{file} = $arg;
    }
    if (my $arg = shift @{$self->extra_argv}) {
        $self->exporter_arg->{file} = $arg;
    }

}

sub run {
    my $self = shift;

    Plack::Util::load_class($self->importer);
    Plack::Util::load_class($self->exporter);

    my $importer = $self->importer->new($self->importer_arg);
    my $exporter = $self->exporter->new($self->exporter_arg);

    $exporter->dump($importer);
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

