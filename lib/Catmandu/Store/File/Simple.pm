package Catmandu::Store::File::Simple;

our $VERSION = '1.09';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use Catmandu::Util;
use Catmandu::Store::File::Simple::Index;
use Catmandu::Store::File::Simple::Bag;
use Data::UUID;
use Catmandu::DirectoryIndex::UUID;
use Catmandu::DirectoryIndex::Number;
use namespace::clean;

with 'Catmandu::FileStore';
with 'Catmandu::Droppable';

has root => (is => 'ro', required => '1');

#DEPRECATED
has uuid => (is => 'ro');

#DEPRECATED
has keysize => (
    is  => 'ro',
    isa => sub {
        Catmandu::Util::check_natural($_[0]);
        croak "keysize needs to be a multiple of 3" unless $_[0] % 3 == 0;
    },
    default => 9
);
has directory_index_package => (is => "ro");
has directory_index_options => (is => "ro", lazy => 1, default => sub {+{};});
has directory_index         => (is => "lazy");

sub _build_directory_index {

    my $self = $_[0];

    if ($self->directory_index_package()) {

        Catmandu::Util::require_package($self->directory_index_package(),
            "Catmandu::DirectoryIndex")
            ->new(%{$self->directory_index_options(),}, base_dir => $self->root());

    }
    elsif ($self->uuid()) {

        Catmandu::DirectoryIndex::UUID->new(base_dir => $self->root());

    }
    else {

        Catmandu::DirectoryIndex::Number->new(
            base_dir => $self->root(),
            keysize  => $self->keysize()
        );

    }

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

DEPRECATED: use directory_index_package and directory_index_options

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::File::Simple> must be integers.

=item uuid

DEPRECATED: use directory_index_package and directory_index_options

If the to a true value, then the Simple store will require UUID-s as keys

=item directory_index_package

package name that translates between id and a directory.

prefix "Catmandu::DirectoryIndex::" can be omitted.

Default: L<Catmandu::DirectoryIndex::Number>

=item directory_index_options

Constructor arguments for the directory_index_package (see above)

=item directory_index

instance of L<Catmandu::DirectoryIndex>.

When supplied, directory_index_package and directory_index_options are ignored.

When not, this object is constructed from directory_index_package and directory_index_options.

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
