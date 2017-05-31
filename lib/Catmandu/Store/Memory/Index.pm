package Catmandu::Store::Memory::Index;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo;
use Carp;
use namespace::clean;

use Data::Dumper;

with 'Catmandu::FileStore::Bag';

sub generator {
    my ($self) = @_;

    my $name       = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return sub {
        state $list = [ keys %$containers ];

        my $key = pop @$list;

        return undef unless $key;

        +{ _id => $key };
    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $name       = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return exists $containers->{$id};
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id   = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    my $name = $self->name;

    $self->store->_files->{$name}->{$id} = +{
        _id      => $id ,
    };

    return $self->get($id);
}

sub get {
    my ($self, $id) = @_;

    croak "Need an $id" unless defined $id;

    my $name       = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return $containers->{$id};
}

sub delete {
    my ($self, $id) = @_;

    croak "Need an $id" unless defined $id;

    my $name       = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    delete $containers->{$id};

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->each(sub {
        my $id = shift->{_id};
        $self->delete($id);
    });

    1;
}

1;
