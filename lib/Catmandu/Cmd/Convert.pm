package Catmandu::Cmd::Convert;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with 'Catmandu::Command';

has importer => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'I',
    default => 'JSON',
    documentation => "The Catmandu::Importer class to use. Defaults to JSON.",
);

has importer_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'i',
    default => sub { +{} },
    documentation => "Pass params to the importer constructor. " .
                     "The file param can also be the 1st non-option argument.",
);

has exporter => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'O',
    default => 'JSON',
    documentation => "The Catmandu::Exporter class to use. Defaults to JSON.",
);

has exporter_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'o',
    default => sub { +{} },
    documentation => "Pass params to the exporter constructor. " .
                     "The file param can also be the 2nd non-option argument.",
);

sub _usage_format {
    "usage: %c %o [file] [file]";
}

sub BUILD {
    my $self = shift;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);

    if (my $file = shift @{$self->extra_argv}) {
        $self->importer_arg->{file} = $file;
    }
    if (my $file = shift @{$self->extra_argv}) {
        $self->exporter_arg->{file} = $file;
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

