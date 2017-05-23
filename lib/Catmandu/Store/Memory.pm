package Catmandu::Store::Memory;

our $VERSION = '0.01';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu::Store::Memory::Index;
use Catmandu::Store::Memory::Bag;
use namespace::clean;

with 'Catmandu::FileStore';

has _files      => (is => 'ro' , lazy => 1  , default => sub { + {} });

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Memory - A Catmandu::FileStore to keep files in memory

=head1 SYNOPSIS

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('Mempory');

    # List all containers
    $store->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new container
    $store->bag->add({ _id => '1234' });

    # Get the container
    my $container = $store->bag('1234');

    # Add a file to the container
    $container->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Stream the contents of a file
    $container->stream(IO::File->new('>foobar.txt'), 'foobar.txt');

    # Delete a file
    $container->delete('foobar.txt');

    # Delete a container
    $store->bag->delete('1234');

=head1 SEE ALSO

L<Catmandu::FileStore::Simple>,
L<Catmandu::FileStore::Memory>,
L<Catmandu::FileStore::Bag>

=cut
