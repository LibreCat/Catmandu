package Catmandu::Cmds::Index;

use 5.010;
use Moose;
use MooseX::Types::IO::All 'IO_All';
use Plack::Util;
use Catmandu;
use JSON::Path;
use lib Catmandu->lib;

with qw(
    Catmandu::Cmd
    Catmandu::Cmd::OptIndex
    Catmandu::Cmd::OptStore
    Catmandu::Cmd::OptVerbose
);

has map => (
    traits => ['Getopt'],
    is => 'rw',
    isa => IO_All,
    coerce => 1,
    documentation => "Path to the index definition file to use."
);

sub _usage_format {
    "usage: %c %o [map_file]"
}

sub BUILD {
    my $self = shift;

    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);
    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);

    if (my $arg = shift @{$self->extra_argv}) {
        $self->map($arg);
    }
}

sub run {
    my $self = shift;

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

sub msg {
    my ($self, $text) = @_;
    local $| = 1;
    if ($self->verbose) {
        say $text;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

