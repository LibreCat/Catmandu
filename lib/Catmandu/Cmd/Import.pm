package Catmandu::Cmd::Import;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with 'Catmandu::Command';

has importer => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'I',
    default => 'JSON',
    documentation => "The Catmandu::Importer class to use. Defaults to JSON.",
);

has importer_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 'i',
    default => sub { +{} },
    documentation => "Pass params to the importer constructor. " .
                     "The file param can also be the 1st non-option argument.",
);

has store => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'S',
    default => 'Simple',
    documentation => "The Catmandu::Store class to use. Defaults to Simple.",
);

has store_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 's',
    default => sub { +{} },
    documentation => "Pass params to the store constructor.",
);

has verbose => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    cmd_aliases => 'v',
    documentation => "Verbose output.",
);

sub _usage_format {
    "usage: %c %o [file]";
}

sub BUILD {
    my $self = shift;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $file = shift @{$self->extra_argv}) {
        $self->importer_arg->{file} = $file;
    }
}

sub run {
    my $self = shift;
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

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

