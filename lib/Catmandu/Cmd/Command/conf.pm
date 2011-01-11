package Catmandu::Cmd::Command::conf;
# VERSION
use Moose;
use Catmandu;
use Catmandu::Util;

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Exporter
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);

    if (my $arg = shift @$args) {
        $self->exporter_arg->{file} = $arg;
    }

    Catmandu::Util::load_class($self->exporter);

    my $exporter = $self->exporter->new($self->exporter_arg);

    print $exporter->dump(Catmandu->conf);
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

=head1 NAME

Catmandu::Cmd::Command::conf - export the project's configuration

