package Catmandu::Cmd::Command::index;
# VERSION
use 5.010;
use Moose;
use MooseX::Types::IO qw(IO);
use File::Slurp qw(slurp);
use Catmandu::Util qw(load_class);
use JSON::Path;

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Index
    Catmandu::Cmd::Opts::Store
    Catmandu::Cmd::Opts::Verbose
);

has map => (
    traits => ['Getopt'],
    is => 'rw',
    isa => IO,
    coerce => 1,
    predicate => 'has_map',
    documentation => "Path to the map definition file to use.",
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);
    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);

    if (my $arg = shift @$args) {
        $self->map($arg);
    }

    load_class($self->index);
    load_class($self->store);

    my $index = $self->index->new($self->index_arg);
    my $store = $self->store->new($self->store_arg);

    my %map = ();

    if ($self->has_map) {
        foreach my $line (split /\n/, slurp($self->map)) {
            $line =~ s/^\s*(.*)\s*$/$1/;
            my ($path, $key) = split /\s+/, $line;
            my $paths = $map{$key} ||= [];
            push @$paths, $path;
        }
    }

    $self->msg("Indexing...");

    my $n = 0;
    if ($self->has_map) {
        $store->each(sub {
            my $obj = shift;
            my $doc = {};

            foreach my $key (keys %map) {
                foreach my $path (@{$map{$key}}) {
                    my @values = JSON::Path->new($path)->values($obj);
                    my $val = join ' ', @values ? @values : ();
                    exists $doc->{$key} ?
                        $doc->{$key} .= $val : $doc->{$key} = $val;
                }
            }

            $self->msg(" $n") if $n % 100 == 0;

            $index->save($doc);

            $n++;
        });
    } else {
        $store->each(sub {
            $self->msg(" $n") if $n % 100 == 0;

            $index->save($_[0]);

            $n++;
        });
    }

    $self->msg("Committing...");

    $index->commit;

    $self->msg($n == 1 ? "Indexed 1 object" : "Indexed $n objects");
}

sub msg {
    my ($self, $text) = @_;
    local $| = 1;
    if ($self->verbose) {
        say $text;
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::Types::IO;
no File::Slurp;
no Catmandu::Util;

1;

=head1 NAME

Catmandu::Cmd::Command::index - index a store

