use MooseX::Declare;

class Catmandu::Cmd::Command::import extends Catmandu::Cmd::Command
    with Catmandu::Cmd::Opts::Importer
    with Catmandu::Cmd::Opts::Store
    with Catmandu::Cmd::Opts::Verbose {
    use Plack::Util;

    method execute ($opts, $args) {
        $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
        $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

        if (my $arg = shift @$args) {
            $self->importer_arg->{file} = $arg;
        }

        my $verbose = $self->verbose;

        Plack::Util::load_class($self->importer);
        Plack::Util::load_class($self->store);

        my $importer = $self->importer->new($self->importer_arg);
        my $store = $self->store->new($self->store_arg);

        my $n = $importer->each(sub {
            $store->save($_[0]);
            if ($verbose) {
                say $_[0]->{_id};
            }
        });

        if ($verbose) {
            say $n == 1 ? "Imported 1 object" : "Imported $n objects";
        }
    }

}

1;

