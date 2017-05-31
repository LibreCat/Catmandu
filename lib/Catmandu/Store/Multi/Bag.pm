package Catmandu::Store::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Hits;
use Moo;
use Catmandu::Util qw(:check);
use Hash::Merge::Simple 'merge';
use namespace::clean;

with 'Catmandu::Bag' , 'Catmandu::FileStore::Bag';

sub generate_id {
    my ($self) = @_;
    # uncoverable statement
    Catmandu::Error->throw( 'generate_id called from ' . __PACKAGE__ . '?!' );
}

sub generator {
    my ($self) = @_;

    # Loop of all stores and find the first one that implements the bag
    # and can create a generator
    my $gen;
    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        $gen = $bag ? $bag->generator : undef ;
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
        my $bag  = $store->bag($self->name);
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
        my $bag  = $store->bag($self->name);
        $bag->add($data) if $bag;
    }
}

sub delete {
    my ($self, $id) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag  = $store->bag($self->name);
        $bag->delete($id) if $bag;
    }
}

sub delete_all {
    my ($self) = @_;

    # By default try to drop the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag  = $store->bag($self->name);
        $bag->delete_all if $bag;
    }
}

sub drop {
    my ($self) = @_;

    # By default try to delete the data from all the stores

    for my $store (@{$self->store->stores}) {
        my $bag  = $store->bag($self->name);
        $bag->drop if $bag;
    }
}

sub commit {
    my ($self) = @_;

    # By default try to commit the data to all the stores

    for my $store (@{$self->store->stores}) {
        my $bag  = $store->bag($self->name);
        $bag->commit if $bag;
    }
}

sub upload {
    my ($self,$io,$id) = @_;

    # Upload in a FileStore should send data, in a normal Store it adds an
    # empty record

    my $rewind;

    for my $store (@{$self->store->stores}) {
        if ($store->does('Catmandu::FileStore')) {
            my $bag  = $store->bag($self->name);
            next unless $bag;
            if ($rewind) {
                # Rewind the stream after first use...
                Catmandu::BadVal->throw("IO stream needs to seekable") unless $io->isa('IO::Seekable');
                $io->seek(0,0);
            }
            $store->bag($self->name)->upload($io,$id) || return undef;
            $rewind = 1;
        }
        else {
            my $bag = $store->bag($self->name);
            $bag->add({ _id => $id}) if $bag;
        }
    }

    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi::Bag - Bag implementation for the Multi store

=cut
