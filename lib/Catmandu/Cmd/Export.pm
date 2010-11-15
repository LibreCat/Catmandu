package Catmandu::Cmd::Export;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with 'MooseX::Getopt::Dashes';

has exporter => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'O',
    default => 'JSON',
    documentation => "The Catmandu::Exporter class to use. Defaults to JSON.",
);

has exporter_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    cmd_aliases => 'o',
    default => sub { +{} },
    documentation => "Pass params to the exporter constructor. " .
                     "The file param can also be the first non-option argument.",
);

has store => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'S',
    default => 'Simple',
    documentation => "The Catmandu::Store class to use. Defaults to Simple.",
);

has store_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    cmd_aliases => 's',
    default => sub { +{} },
    documentation => "Pass params to the store constructor.",
);

sub _usage_format {
    "usage: %c %o <file>";
}

sub BUILD {
    my $self = shift;

    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $file = $self->extra_argv->[0]) {
        $self->importer_arg->{file} = $file;
    }
}

sub run {
    my $self = shift;

    Plack::Util::load_class($self->exporter);
    Plack::Util::load_class($self->store);
    my $exporter = $self->exporter->new($self->exporter_arg);
    my $store = $self->store->new($self->store_arg);

    $exporter->dump($store);
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

