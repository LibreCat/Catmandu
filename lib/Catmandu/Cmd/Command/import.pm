package Catmandu::Cmd::Command::import;
# VERSION
use Moose;
use Catmandu::Util qw(load_class);

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Importer
    Catmandu::Cmd::Opts::Store
    Catmandu::Cmd::Opts::Fix
    Catmandu::Cmd::Opts::Verbose
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $arg = shift @$args) {
        $self->importer_arg->{file} = $arg;
    }

    load_class($self->importer);
    load_class($self->store);

    my $importer = $self->importer->new($self->importer_arg);
    my $store = $self->store->new($self->store_arg);

    if ($self->has_fix) {
        $importer = $self->fixer->fix($importer);
    }

    my $verbose = $self->verbose;

    my $n = $importer->each(sub {
        my $obj = $_[0];
        $store->save($obj);
        if ($verbose) {
            say $obj->{_id};
        }
    });

    if ($verbose) {
        say $n == 1 ? "Imported 1 object" : "Imported $n objects";
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Util;

1;

=head1 NAME

Catmandu::Cmd::Command::import - import a data file into a store

