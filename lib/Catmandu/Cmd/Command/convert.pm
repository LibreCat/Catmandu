package Catmandu::Cmd::Command::convert;

use namespace::autoclean;
use Moose;
use Catmandu::Util qw(load_class);
use File::Slurp qw(slurp);

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Importer
    Catmandu::Cmd::Opts::Exporter
    Catmandu::Cmd::Opts::Fix
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);

    if (my $arg = shift @$args) {
        $self->importer_arg->{file} = $arg;
    }
    if (my $arg = shift @$args) {
        $self->exporter_arg->{file} = $arg;
    }

    load_class($self->importer);
    load_class($self->exporter);

    my $importer = $self->importer->new($self->importer_arg);
    my $exporter = $self->exporter->new($self->exporter_arg);

    if ($self->has_fix) {
        $exporter->dump(Catmandu::Fixer->new($self->fix_list)->fix($importer));
    } else {
        $exporter->dump($importer);
    }
}

__PACKAGE__->meta->make_immutable;

1;

