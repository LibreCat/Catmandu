package Catmandu::Cmds::Import;

use 5.010;
use Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with qw(
    Catmandu::Cmd
    Catmandu::Cmd::OptImporter
    Catmandu::Cmd::OptStore
    Catmandu::Cmd::OptVerbose
);

sub _usage_format {
    "usage: %c %o [import_file]";
}

sub BUILD {
    my $self = shift;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $arg = shift @{$self->extra_argv}) {
        $self->importer_arg->{file} = $arg;
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

