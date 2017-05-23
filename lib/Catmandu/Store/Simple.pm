package Catmandu::Store::Simple;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use Catmandu::Util;
use Catmandu::Store::Simple::Index;
use Catmandu::Store::Simple::Bag;
use namespace::clean;

with 'Catmandu::FileStore';

has root     => (is => 'ro', required => '1');
has keysize  => (is => 'ro', default => 9 , trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3" unless $self->keysize % 3 == 0;
}

sub path_string {
    my ($self,$key) = @_;

    my $keysize = $self->keysize;

    return undef unless $key =~ /^\d+$/;

    return undef unless length($key) && length($key) <= $keysize;

    $key =~ s/^0+//;

    my $long_key = sprintf "%-${keysize}.${keysize}d", $key;

    my $path = $self->root . "/" . join("/", unpack('(A3)*', $long_key));

    $path;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Simple - A Catmandu::FileStore to store files on disk

=head1 SYNOPSIS

    # From the command line

    # Export a list of all file containers
    $ catmandu export Simple --root t/data to YAML

    # Export a list of all files in container '1234'
    $ catmandu export Simple --root t/data --bag 1234 to YAML

    # Add a file to the container '1234'
    $ catmandu stream /tmp/myfile.txt to Simple --root t/data --bag 1234 --id myfile.txt

    # Download the file 'myfile.txt' from the container '1234'
    $ catmandu stream Simple --root t/data --bag 1234 --id myfile.txt to /tmp/output.txt

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('Simple' , root => 't/data');

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

=head1 DESCRIPTION

L<Catmandu::Store::Simple> is a L<Catmandu::FileStore> implementation to
store files in a directory structure. Each L<Catmandu::FileStore::Bag> is
a deeply nested directory based on the numeric identifier of the bag. E.g.

    $store->bag(1234)

is stored as

    ${ROOT}/000/001/234

In this directory all the L<Catmandu::FileStore::Bag> items are stored as
flat files.

=head1 CONFIGURATION

=over

=item root

The root directory where to store all the files. Required.

=item keysize

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::Simple> must be integers.

=back

=head1 SEE ALSO

L<Catmandu::FileStore::Memory>,
L<Catmandu::FileStore::Bag>

=cut
