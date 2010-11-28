package Catmandu::Cmd::Export;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with qw(
    Catmandu::Command
    Catmandu::Command::OptExporter
    Catmandu::Command::OptStore
);

has load => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'l',
    documentation => "The id of a single object to load and export.",
);

sub _usage_format {
    "usage: %c %o [export_file]";
}

sub BUILD {
    my $self = shift;

    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $arg = shift @{$self->extra_argv}) {
        $self->exporter_arg->{file} = $arg;
    }
}

sub run {
    my $self = shift;

    Plack::Util::load_class($self->exporter);
    Plack::Util::load_class($self->store);

    my $exporter = $self->exporter->new($self->exporter_arg);
    my $store = $self->store->new($self->store_arg);

    if ($self->load) {
        $exporter->dump($store->load_strict($self->load));
    } else {
        $exporter->dump($store);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

