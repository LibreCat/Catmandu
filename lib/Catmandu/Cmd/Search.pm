package Catmandu::Cmd::Search;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with 'Catmandu::Command';

has index => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'I',
    default => 'Simple',
    documentation => "The Catmandu::Index class to use. Defaults to Simple.",
);

has index_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'i',
    default => sub { +{} },
    documentation => "Pass params to the index constructor.",
);

has exporter => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'O',
    default => 'JSON',
    documentation => "The Catmandu::Exporter class to use. Defaults to JSON.",
);

has exporter_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'o',
    default => sub { +{} },
    documentation => "Pass params to the exporter constructor. " .
                     "The file param can also be the 1st non-option argument.",
);

has query => (
    traits => ['NoGetopt'],
    is => 'rw',
    isa => 'Str',
);

sub _usage_format {
    "usage: %c %o query"
}

sub BUILD {
    my $self = shift;

    $self->index =~ /::/ or $self->index("Catmandu::Index::" . $self->index);
    $self->exporter =~ /::/ or $self->exporter("Catmandu::Exporter::" . $self->exporter);


    my $query = shift @{$self->extra_argv};

    unless ($query) {
        print $self->usage->text;
        exit 1;
    }

    $self->query($query);
} 

sub run {
    my $self = shift;

    Plack::Util::load_class($self->index);
    Plack::Util::load_class($self->exporter);

    my $index    = $self->index->new($self->index_arg);
    my $exporter = $self->exporter->new($self->exporter_arg);

    my ($hits, $total_hits) = $index->find($self->query);

    print STDERR $self->query. " : $total_hits hits\n";

    foreach my $h (@$hits) {
        $exporter->dump($h->get_fields);
    }
}


__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

