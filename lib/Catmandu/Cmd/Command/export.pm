use MooseX::Declare;

class Catmandu::Cmd::Command::export extends Catmandu::Cmd::Command
    with Catmandu::Cmd::Opts::Exporter
    with Catmandu::Cmd::Opts::Store {
    use Plack::Util;

    has load => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        cmd_aliases => 'l',
        documentation => "The id of a single object to load and export.",
    );

    method execute ($opts, $args) {
        $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);
        $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

        if (my $arg = shift @$args) {
            $self->exporter_arg->{file} = $arg;
        }

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
}

1;

