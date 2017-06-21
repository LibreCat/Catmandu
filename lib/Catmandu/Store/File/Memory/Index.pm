package Catmandu::Store::File::Memory::Index;

our $VERSION = '1.06';

use Catmandu::Sane;
use Moo;
use Carp;
use namespace::clean;

use Data::Dumper;

with 'Catmandu::Bag', 'Catmandu::FileBag::Index', 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $name = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return sub {
        state $list = [keys %$containers];

        my $key = pop @$list;

        return undef unless $key;

        +{_id => $key};
    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $name = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return exists $containers->{$id};
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    my $name = $self->name;

    $self->store->_files->{$name}->{$id} = +{_id => $id,};

    return $self->get($id);
}

sub get {
    my ($self, $id) = @_;

    croak "Need an $id" unless defined $id;

    my $name = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    return $containers->{$id};
}

sub delete {
    my ($self, $id) = @_;

    croak "Need an $id" unless defined $id;

    my $name = $self->name;
    my $containers = $self->store->_files->{$name} // {};

    delete $containers->{$id};

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $id = shift->{_id};
            $self->delete($id);
        }
    );

    1;
}

sub drop {
    $_[0]->delete_all;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Memory::Index - Index of all "Folders" in a Catmandu::Store::File::Memory

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::Memory');

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

A L<Catmandu::Store::File::Memory::Index> contains all "folders" available in a
L<Catmandu::Store::File::Memory> FileStore. All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 FOLDERS
All files in a L<Catmandu::Store::File::Memory> are organized in "folders". To add
a "folder" a new record needs to be added to the L<Catmandu::Store::File::Memory::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in Memory stores. To add more
metadata fields to a Memory store a L<Catmandu::Plugin::SideCar> is required.

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

Execute C<callback> on every "folder" in the Memory store. See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($id)

Returns true when a "folder" with identifier $id exists.

=head2 add($hash)

Adds a new "folder" to the Memory store. The $hash must contain an C<_id> field.

=head2 get($id)

Returns a hash containing the metadata of the folder. In the Memory store this hash
will contain only the "folder" idenitifier.

=head2 files($id)

Return the L<Catmandu::Store::File::Memory::Bag> that contains all "files" in the "folder"
with identifier $id.

=head2 delete($id)

Delete the "folder" with identifier $id, if exists.

=head2 delete_all()

Delete all folders in this store.

=head2 drop()

Delete the store.

=head1 SEE ALSO

L<Catmandu::Store::File::Memory::Bag> ,
L<Catmandu::Store::File::Memory> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut
