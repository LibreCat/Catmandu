package Catmandu::Store::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Hash::Merge::Simple qw(merge);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    # Loop of all stores and find the first one that implements the bag
    # and can create a generator
    my $gen;
    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $gen = $bag ? $bag->generator : undef;
        last if defined($gen);
    }

    return undef unless $gen;

    sub {
        my $item = $gen->();
        return undef unless $item;
        return $item;
    };
}

sub get {
    my ($self, $id) = @_;

    # Loop over all the bags and merge the results of the records found
    # Required in case of Store/FileStore combinations where each part
    # can contain different metadata
    my $found  = 0;
    my $result = {};

    for my $store (@{$self->store->stores}) {
        my $bag  = $store->bag($self->name);
        my $item = $bag ? $bag->get($id) : undef;
        if ($item) {
            $found  = 1;
            $result = merge $result , $item;
        }
    }

    return $found ? $result : undef;
}

sub add {
    my ($self, $data) = @_;

    # By default try to add the data to all the stores
    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->add($data) if $bag;
    }

    1;
}

sub delete {
    my ($self, $id) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->delete($id) if $bag;
    }

    1;
}

sub delete_all {
    my ($self) = @_;

    # By default try to drop the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->delete_all if $bag;
    }

    1;
}

sub drop {
    my ($self) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->drop if $bag && $bag->does('Catmandu::Droppable');
    }

    1;
}

sub commit {
    my ($self) = @_;

    # By default try to commit the data to all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->commit if $bag;
    }

    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi::Bag - Bag implementation for the Multi store

=cut
