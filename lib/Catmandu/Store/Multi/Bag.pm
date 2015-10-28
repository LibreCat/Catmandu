package Catmandu::Store::Multi::Bag;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Hits;
use Moo;

with 'Catmandu::Bag';

sub generator {
    my ($self) = @_;
    $self->store->stores->[0]->bag($self->name)->generator;
}

sub get {
    my ($self, $id) = @_;
    $self->store->stores->[0]->bag($self->name)->get($id);
}

sub add {
    my ($self, $data) = @_;
    for my $store (@{$self->store->stores}) {
        $store->bag($self->name)->add($data);
    }
}

sub delete {
    my ($self, $id) = @_;
    for my $store (@{$self->store->stores}) {
        $store->bag($self->name)->delete($id);
    }
}

sub delete_all {
    my ($self) = @_;
    for my $store (@{$self->store->stores}) {
        $store->bag($self->name)->delete_all;
    }
}

sub commit {
    my ($self) = @_;
    for my $store (@{$self->store->stores}) {
        $store->bag($self->name)->commit;
    }
}

1;

