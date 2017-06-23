package Catmandu::Store::File::Multi::Index;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;

extends 'Catmandu::Store::Multi::Bag';

with 'Catmandu::FileBag::Index';

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Multi::Index - Index of all "Folders" in a Catmandu::Store::File::Multi

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

A L<Catmandu::Store::File::Multi::Index> contains all "folders" available in a
L<Catmandu::Store::File::Multi> FileStore. All methods of L<Catmandu::Bag>,
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

Execute C<callback> on every "folder" in the File::Multi store. See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($id)

Returns true when a "folder" with identifier $id exists.

=head2 add($hash)

Adds a new "folder" to the File::Multi store. The $hash must contain an C<_id> field.

=head2 get($id)

Returns a hash containing the metadata of the folder. In the File::Multi store this hash
will contain only the "folder" idenitifier.

=head2 files($id)

Return the L<Catmandu::Store::File::Multi::Bag> that contains all "files" in the "folder"
with identifier $id.

=head2 delete($id)

Delete the "folder" with identifier $id, if exists.

=head2 delete_all()

Delete all folders in this store.

=head2 drop()

Delete the store.

=head1 SEE ALSO

L<Catmandu::Store::File::Multi::Bag> ,
L<Catmandu::Store::File::Multi> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut
