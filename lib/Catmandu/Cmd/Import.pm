package Catmandu::Cmd::Import;

use 5.010;
use Any::Moose;
use Plack::Util;
use Catmandu;
use lib Catmandu->lib;

with any_moose('X::Getopt::Dashes');

has importer => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'I', default => 'JSON');
has importer_arg => (traits => ['Getopt'], is => 'rw', isa => 'HashRef', cmd_aliases => 'i', default => sub { +{} });
has store => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'S', default => 'Simple');
has store_arg => (traits => ['Getopt'], is => 'rw', isa => 'HashRef', cmd_aliases => 's', default => sub { +{} });

sub BUILD {
    my $self = shift;

    $self->importer =~ /::/ or $self->importer("Catmandu::Importer::" . $self->importer);
    $self->store =~ /::/ or $self->store("Catmandu::Store::" . $self->store);

    if (my $file = $self->extra_argv->[1]) {
        $self->importer_arg->{file} = $file;
    }
}

sub run {
    my $self = shift;

    Plack::Util::load_class($self->importer);
    Plack::Util::load_class($self->store);
    my $importer = $self->importer->new($self->importer_arg);
    my $store = $self->store->new($self->store_arg);

    my $count = $importer->each(sub {
        my $obj = shift;
        $store->save($obj);
    });

    say $count == 1 ? 
        "Imported 1 object" :
        "Imported $count objects";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
__PACKAGE__;

