package Catmandu::Store::File::Simple;

our $VERSION = '1.0604';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use Catmandu::Util;
use Catmandu::Store::File::Simple::Index;
use Catmandu::Store::File::Simple::Bag;
use Data::UUID;
use namespace::clean;

with 'Catmandu::FileStore';
with 'Catmandu::Droppable';

has root    => (is => 'ro', required => '1');
has uuid    => (is => 'ro', trigger  => 1);
has keysize => (is => 'ro', default  => 9, trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3"
        unless $self->keysize % 3 == 0;
}

sub _trigger_uuid {
    my $self = shift;

    $self->{keysize} = 36;
}

sub path_string {
    my ($self, $key) = @_;

    my $keysize = $self->keysize;

    # Allow all hexidecimal numbers
    $key =~ s{[^A-F0-9-]}{}g;

    # If the key is a UUID then the matches need to be exact
    if ($self->uuid) {
        try {
            Data::UUID->new->from_string($key);
        }
        catch {
            return undef;
        };
    }
    else {
        return undef unless length($key) && length($key) <= $keysize;
        $key =~ s/^0+//;
        $key = sprintf "%-${keysize}.${keysize}d", $key;
    }

    my $path = $self->root . "/" . join("/", unpack('(A3)*', $key));

    $path;
}

sub drop {
    my ($self) = @_;

    $self->index->delete_all;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Simple - A Catmandu::FileStore to store files on disk

=head1 SYNOPSIS

    # From the command line

    # Export a list of all file containers
    $ catmandu export File::Simple --root t/data to YAML

    # Export a list of all files in container '1234'
    $ catmandu export File::Simple --root t/data --bag 1234 to YAML

    # Add a file to the container '1234'
    $ catmandu stream /tmp/myfile.txt to File::Simple --root t/data --bag 1234 --id myfile.txt

    # Download the file 'myfile.txt' from the container '1234'
    $ catmandu stream File::Simple --root t/data --bag 1234 --id myfile.txt to /tmp/output.txt

    # Delete the file 'myfile.txt' from the container '1234'
    $ catmandu delete File::Simple --root t/data --bag 1234 --id myfile.txt

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('File::Simple' , root => 't/data');

    my $index = $store->index;

    # List all folder
    $index->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $index->add({ _id => '1234' });

    # Get the folder
    my $files = $index->files('1234');

    # Add a file to the folder
    $files->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Retrieve a file
    my $file = $files->get('foobar.txt');

    # Stream the contents of a file
    $files->stream(IO::File->new('>foobar.txt'), $file);

    # Delete a file
    $files->delete('foobar.txt');

    # Delete a folder
    $index->delete('1234');

=head1 DESCRIPTION

L<Catmandu::Store::File::Simple> is a L<Catmandu::FileStore> implementation to
store files in a directory structure. Each L<Catmandu::FileBag> is
a deeply nested directory based on the numeric identifier of the bag. E.g.

    $store->bag(1234)

is stored as

    ${ROOT}/000/001/234

In this directory all the L<Catmandu::FileBag> items are stored as
flat files.

=head1 METHODS

=head2 new(root => $path , [ keysize => NUM , uuid => 1])

Create a new Catmandu::Store::File::Simple with the following configuration
parameters:

=over

=item root

The root directory where to store all the files. Required.

=item keysize

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::File::Simple> must be integers.

=item uuid

If the to a true value, then the Simple store will require UUID-s as keys

=back

=head1 INHERITED METHODS

This Catmandu::FileStore implements:

=over 3

=item L<Catmandu::FileStore>

=item L<Catmandu::Droppable>

=back

The index Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag::Index>

=item L<Catmandu::Droppable>

=back

The file Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=item L<Catmandu::Droppable>

=back

=head1 SEE ALSO

L<Catmandu::Store::File::Simple::Index>,
L<Catmandu::Store::File::Simple::Bag>,
L<Catmandu::Plugin::SideCar>,
L<Catmandu::FileStore>

=cut
