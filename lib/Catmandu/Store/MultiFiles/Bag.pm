package Catmandu::Store::MultiFiles::Bag;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Hits;
use Moo;
use namespace::clean;

with 'Catmandu::Store::Multi::Base', 'Catmandu::FileStore::Bag';

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
