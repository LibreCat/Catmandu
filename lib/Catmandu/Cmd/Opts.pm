package Catmandu::Cmd::Opts;
# VERSION

package Catmandu::Cmd::Opts::Verbose;
# VERSION
use Moose::Role;

has verbose => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    cmd_aliases => 'v',
    documentation => "Verbose output.",
);

no Moose::Role;

package Catmandu::Cmd::Opts::Exporter;
# VERSION
use Moose::Role;

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
    predicate => 'has_exporter_arg',
    documentation => "Pass params to the exporter constructor.",
);

has pretty => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    predicate => 'has_pretty',
    documentation => "Pretty print exported objects. Equivalent to '-o pretty=1'.",
);

sub BUILD {
    my $self = shift;

    if ($self->has_pretty) {
        $self->exporter_arg->{pretty} = $self->pretty;
    }
}

no Moose::Role;

package Catmandu::Cmd::Opts::Importer;
# VERSION
use Moose::Role;

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
    predicate => 'has_importer_arg',
    documentation => "Pass params to the importer constructor.",
);

no Moose::Role;

package Catmandu::Cmd::Opts::Index;
# VERSION
use Moose::Role;

has index => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_aliases => 'T',
    default => 'Simple',
    documentation => "The Catmandu::Index class to use. Defaults to Simple.",
);

has index_arg => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    cmd_aliases => 't',
    default => sub { +{} },
    documentation => "Pass params to the index constructor.",
);

no Moose::Role;

package Catmandu::Cmd::Opts::Store;
# VERSION
use Moose::Role;

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
    predicate => 'has_store_arg',
    documentation => "Pass params to the store constructor.",
);

no Moose::Role;

package Catmandu::Cmd::Opts::Fix;
# VERSION
use Moose::Role;
use File::Slurp qw(slurp);
use Catmandu::Fixer;

has fix => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    predicate => 'has_fix',
    documentation => "Path to the fix definition file to use.",
);

has fixer => (
    traits => ['NoGetopt'],
    is => 'ro',
    isa => 'Catmandu::Fixer',
    lazy => 1,
    builder => '_build_fixer',
);

sub _build_fixer {
    my $self = shift;
    my @args = $self->has_fix ? slurp($self->fix) : ();
    Catmandu::Fixer->new(@args);
}

no Moose::Role;
no File::Slurp;

1;

