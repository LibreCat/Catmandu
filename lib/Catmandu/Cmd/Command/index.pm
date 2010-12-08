use MooseX::Declare;

class Catmandu::Cmd::Command::index extends Catmandu::Cmd::Command
    with Catmandu::Cmd::Opts::Index
    with Catmandu::Cmd::Opts::Store
    with Catmandu::Cmd::Opts::Verbose {
    use MooseX::Types::IO::All qw(IO_All);
    use Plack::Util;
    use JSON::Path;

    has map => (
        traits => ['Getopt'],
        is => 'rw',
        isa => IO_All,
        coerce => 1,
        documentation => "Path to the index definition file to use.",
    );

    method execute ($opts, $args) {
        $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);
        $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);

        if (my $arg = shift @$args) {
            $self->map($arg);
        }

        Plack::Util::load_class($self->index);
        Plack::Util::load_class($self->store);

        my $index = $self->index->new($self->index_arg);
        my $store = $self->store->new($self->store_arg);

        my %map = ();

        foreach my $line (split /\n/, $self->map->slurp) {
            $line =~ s/^\s*(.*)\s*$/$1/;
            my ($path, $key) = split /\s+/, $line;
            my $paths = $map{$key} ||= [];
            push @$paths, $path;
        }

        $self->msg("Indexing...");

        my $n = 0;
        $store->each(sub {
            my $obj = shift;

            my $doc = {};

            foreach my $key (keys %map) {
                foreach my $path (@{$map{$key}}) {
                    my $val = join ' ', JSON::Path->new($path)->values($obj);
                    exists $doc->{$key} ?
                        $doc->{$key} .= $val : $doc->{$key} = $val;
                }
            }

            $self->msg(" $n") if $n % 100 == 0;

            $index->save($doc);

            $n++;
        });

        $self->msg("Committing...");

        $index->commit;

        $self->msg($n == 1 ? "Indexed 1 object" : "Indexed $n objects");
    }

    method msg (Str $text) {
        local $| = 1;
        if ($self->verbose) {
            say $text;
        }
    }

}

1;

