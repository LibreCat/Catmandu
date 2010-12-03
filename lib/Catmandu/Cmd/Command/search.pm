use MooseX::Declare;

class Catmandu::Cmd::Command::search extends Catmandu::Cmd::Command
    with Catmandu::Cmd::Opts::Index
    with Catmandu::Cmd::Opts::Exporter
    with Catmandu::Cmd::Opts::Store {
    use Plack::Util;

    has limit => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Int',
        predicate => 'has_limit',
        documentation => "Maximum number of objects to return.",
    );

    has start => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Int',
        default => 0,
        documentation => "Number of objects to skip.",
    );

    has query => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        cmd_aliases => 'q',
        documentation => "The query string. Can also be the first non-option argument.",
    );

    method execute ($opts, $args) {
        my $q = shift @$args || $self->query;

        if (! $q) {
            $self->usage->die;
        }

        $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);
        $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);
        $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

        Plack::Util::load_class($self->index);
        Plack::Util::load_class($self->exporter);
        Plack::Util::load_class($self->store);

        my $index = $self->index->new($self->index_arg);
        my $exporter = $self->exporter->new($self->exporter_arg);

        my %opts = (start => $self->start);
        $opts{limit} = $self->limit                        if $self->has_limit;
        $opts{reify} = $self->store->new($self->store_arg) if $self->has_store_arg;

        my ($hits, $total_hits) = $index->search($q, %opts);

        say STDERR qq($total_hits hits for "$q");

        foreach (@$hits) {
            $exporter->dump($_);
        }
    }
}

1;

