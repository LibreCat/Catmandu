use MooseX::Declare;

class Catmandu::Cmd::Command::convert extends Catmandu::Cmd::Command 
    with Catmandu::Cmd::Opts::Importer
    with Catmandu::Cmd::Opts::Exporter {
    use Plack::Util;

    method execute ($opts, $args) {
        $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
        $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);

        if (my $arg = shift @$args) {
            $self->importer_arg->{file} = $arg;
        }
        if (my $arg = shift @$args) {
            $self->exporter_arg->{file} = $arg;
        }

        Plack::Util::load_class($self->importer);
        Plack::Util::load_class($self->exporter);

        my $importer = $self->importer->new($self->importer_arg);
        my $exporter = $self->exporter->new($self->exporter_arg);

        $exporter->dump($importer);
    }
}

1;

