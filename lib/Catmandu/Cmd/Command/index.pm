package Catmandu::Cmd::Command::index;

use namespace::autoclean;
use Moose;
use MooseX::Types::IO qw(IO);
use File::Slurp qw(slurp);
use Plack::Util;
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
    documentation => "Path to the index definition file to use.",
);

sub execute {
    my ($self, $opts, $args) = @_;

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

    foreach my $line (split /\n/, slurp($self->map)) {
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

sub msg {
    my ($self, $text) = @_;
    local $| = 1;
    if ($self->verbose) {
        say $text;
    }
}

__PACKAGE__->meta->make_immutable;

1;

