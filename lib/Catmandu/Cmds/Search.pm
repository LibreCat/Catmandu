package Catmandu::Cmds::Search;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with qw(
    Catmandu::Cmd
    Catmandu::Cmd::OptExporter
    Catmandu::Cmd::OptIndex
    Catmandu::Cmd::OptStore
);

has limit => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Int',
    predicate => 'has_limit',
    documentation => ".",
);

has start => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Int',
    default => 0,
    documentation => ".",
);

has query => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'q',
    documentation => "The query string.",
);

sub _usage_format {
    "usage: %c %o [query]"
}

sub BUILD {
    my $self = shift;

    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);
    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $arg = shift @{$self->extra_argv}) {
        $self->query($arg);
    }
} 

sub run {
    my $self = shift;
    my $q = $self->query;

    if (! $q) {
        print $self->usage->text;
        exit 1;
    }

    Plack::Util::load_class($self->index);
    Plack::Util::load_class($self->exporter);
    Plack::Util::load_class($self->store);

    my $index = $self->index->new($self->index_arg);
    my $exporter = $self->exporter->new($self->exporter_arg);

    my %opts = (start => $self->start);
    $opts{limit} = $self->limit if $self->has_limit;
    $opts{reify} = $self->store->new($self->store_arg) if $self->has_store_arg;

    my ($hits, $total_hits) = $index->search($q, %opts);

    say STDERR qq($total_hits hits for "$q");

    foreach (@$hits) {
        $exporter->dump($_);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

