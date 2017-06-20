package Catmandu::Store::Multi::Base;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Hits;
use Moo;
use Hash::Merge::Simple qw(merge);
use namespace::clean;

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
        return $self->get($item->{_id});
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
        my $bag = $store->bag($self->name);
        my $item = $bag ? $bag->get($id) : undef;
        if ($item) {
            $found = 1;
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
}

sub delete {
    my ($self, $id) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->delete($id) if $bag;
    }
}

sub delete_all {
    my ($self) = @_;

    # By default try to drop the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->delete_all if $bag;
    }
}

sub drop {
    my ($self) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->drop if $bag && $bag->does('Catmandu::Droppable');
    }
}

sub commit {
    my ($self) = @_;

    # By default try to commit the data to all the stores

    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $bag->commit if $bag;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi::Base - Base implementation for a multistore

=cut
