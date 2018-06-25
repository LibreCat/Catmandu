package Catmandu::Store::File::Simple::Index;

our $VERSION = '1.09';

use Catmandu::Sane;
use Moo;
use Path::Tiny;
use Carp;
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag::Index';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    return sub {

        state $iter = $self->store->directory_index()->generator();

        my $mapping = $iter->();

        return unless defined $mapping;

        $self->get($mapping->{_id});

    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    $self->log->debug("Checking exists $id");

    defined($self->store->directory_index->get($id));
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    $self->store->directory_index->add($id);
}

sub get {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $mapping = $self->store->directory_index->get($id);

    defined($mapping) ? {_id => $id} : undef;
}

sub delete {
    my ($self, $id) = @_;

    croak "Need a key" unless defined $id;

    $self->store->directory_index->delete($id);
}

sub delete_all {
    my ($self) = @_;

    $self->store->directory_index->delete_all;
}

sub drop {
    $_[0]->delete_all;
}

sub commit {
    return 1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Simple::Index - Index of all "Folders" in a Catmandu::Store::File::Simple

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::Simple' , root => 't/data');

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

A L<Catmandu::Store::File::Simple::Index> contains all "folders" available in a
L<Catmandu::Store::File::Simple> FileStore. All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 FOLDERS

All files in a L<Catmandu::Store::File::Simple> are organized in "folders". To add
a "folder" a new record needs to be added to the L<Catmandu::Store::File::Simple::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in Simple stores. To add more
metadata fields to a Simple store a L<Catmandu::Plugin::SideCar> is required.

=head1 FILES

Files can be accessed via the "folder" identifier:

    my $files = $index->files('1234');

Use the C<upload> method to add new files to a "folder". Use the C<download> method
to retrieve files from a "folder".

    $files->upload(IO::File->new("</tmp/data.txt"),'data.txt');

    my $file = $files->get('data.txt');

    $files->download(IO::File->new(">/tmp/data.txt"),$file);

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag::Index>

=item L<Catmandu::Droppable>

=back

=cut
