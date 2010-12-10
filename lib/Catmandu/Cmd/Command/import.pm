package Catmandu::Cmd::Command::import;

use namespace::autoclean;
use Moose;
use Plack::Util;

extends qw(Catmandu::Cmd::Command);

with qw(
    Catmandu::Cmd::Opts::Importer
    Catmandu::Cmd::Opts::Store
    Catmandu::Cmd::Opts::Verbose
);

sub execute {
    my ($self, $opts, $args) = @_;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $arg = shift @$args) {
        $self->importer_arg->{file} = $arg;
    }

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

1;

