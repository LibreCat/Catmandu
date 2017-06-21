package Catmandu::Store::File::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;

extends 'Catmandu::Store::Multi::Bag';

with 'Catmandu::FileBag';

sub upload {
    my ($self, $io, $id) = @_;

    # Upload in a FileStore should send data, in a normal Store it adds an
    # empty record

    my $rewind;

    for my $store (@{$self->store->stores}) {
        if ($store->does('Catmandu::FileStore')) {
            my $bag = $store->bag($self->name);
            next unless $bag;
            if ($rewind) {

                # Rewind the stream after first use...
                Catmandu::BadVal->throw("IO stream needs to seekable")
                    unless $io->isa('IO::Seekable');
                $io->seek(0, 0);
            }
            $store->bag($self->name)->upload($io, $id) || return undef;
            $rewind = 1;
        }
        else {
            my $bag = $store->bag($self->name);
            $bag->add({_id => $id}) if $bag;
        }
    }

    1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Multi::Bag - Index of all "files" in a Catmandu::Store::File::Multi "folder"

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::Multi' , stores [
        Catmandu->store('File::Simple', root => '/data1/files') ,
        Catmandu->store('File::Simple', root => '/data1/files_copy') ,
    ]);

    my $index = $store->index;

    # List all containers
    $index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $index->add({_id => '1234'});

    # Delete a folder
    $index->delete(1234);

    # Get a folder
    my $folder = $index->get(1234);

    # Get the files in an folder
    my $files = $index->files(1234);

    $files->each(sub {
        my $file = shift;

        my $name         = $file->_id;
        my $size         = $file->size;
        my $content_type = $file->content_type;
        my $created      = $file->created;
        my $modified     = $file->modified;

        $file->stream(IO::File->new(">/tmp/$name"), file);
    });

    # Add a file
    $files->upload(IO::File->new("<data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

    # Delete a file
    $files->delete("data.dat");

    # Delete a folders
    $index->delete("1234");

=head1 DESCRIPTION

A L<Catmandu::Store::File::Multi::Bag> contains all "files" available in a
L<Catmandu::Store::File::Multi> FileStore "folder". All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 FOLDERS

All files in a L<Catmandu::Store::File::Multi> are organized in "folders". To add
a "folder" a new record needs to be added to the L<Catmandu::Store::File::Multi::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in File::Multi stores. To add more
metadata fields to a File::Multi store a L<Catmandu::Plugin::SideCar> is required.

=head1 FILES

Files can be accessed via the "folder" identifier:

    my $files = $index->files('1234');

Use the C<upload> method to add new files to a "folder". Use the C<download> method
to retrieve files from a "folder".

    $files->upload(IO::File->new("</tmp/data.txt"),'data.txt');

    my $file = $files->get('data.txt');

    $files->download(IO::File->new(">/tmp/data.txt"),$file);

=head1 METHODS

=head2 each(\&callback)

Execute C<callback> on every "file" in the File::Multi store "folder". See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($name)

Returns true when a "file" with identifier $name exists.

=head2 add($hash)

Adds a new "file" to the File::Multi store "folder". It is very much advised to use the
C<upload> method below to add new files

=head2 get($id)

Returns a hash containing the metadata of the file. The hash contains:

    * _id : the file name
    * size : file file size
    * content_type : the content_type
    * created : the creation date of the file
    * modified : the modification date of the file
    * _stream: a callback function to write the contents of a file to an L<IO::Handle>

If is very much advised to use the C<stream> method below to retrieve files from
the store.

=head2 delete($name)

Delete the "file" with name $name, if exists.

=head2 delete_all()

Delete all files in this folder.

=head2 upload(IO::Handle,$name)

Upload the IO::Handle reference to the File::Multi store "folder" and use $name as identifier.

=head2 stream(IO::Handle,$file)

Write the contents of the $file returned by C<get> to the IO::Handle.

=head1 SEE ALSO

L<Catmandu::Store::File::Multi::Bag> ,
L<Catmandu::Store::File::Multi> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut
