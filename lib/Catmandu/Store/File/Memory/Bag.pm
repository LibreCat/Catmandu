package Catmandu::Store::File::Memory::Bag;

our $VERSION = '1.0605';

use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(content_type);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $name = $self->name;
    my $files = $self->store->_files->{$name} // {};

    sub {
        state $ids = [keys %$files];

        my $id = pop @$ids;

        return undef unless $id;

        return $self->get($id);
    };
}

sub exists {
    my ($self, $id) = @_;

    my $name = $self->name;
    my $files = $self->store->_files->{$name} // {};

    exists $files->{$id};
}

sub get {
    my ($self, $id) = @_;

    my $name = $self->name;
    my $files = $self->store->_files->{$name} // {};

    $files->{$id};
}

sub add {
    my ($self, $data) = @_;

    my $id = $data->{_id};
    my $io = $data->{_stream};

    delete $data->{_stream};

    my $name = $self->name;

    my $str = Catmandu::Util::read_io($io);

    $self->store->_files->{$name}->{$id} = {
        _id          => $id,
        size         => length $str,
        md5          => '',
        content_type => content_type($id),
        created      => time,
        modified     => time,
        _stream      => sub {
            my $io = $_[0];

            Catmandu::Error->throw("no io defined or not writable")
                unless defined($io);

            $io->write($str);
        },
        %$data
    };

    1;
}

sub delete {
    my ($self, $id) = @_;

    my $name = $self->name;
    my $files = $self->store->_files->{$name} // {};

    delete $files->{$id};
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );

    1;
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

Catmandu::Store::File::Memory::Bag - Index of all "files" in a Catmandu::Store::File::Memory "folder"

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

A L<Catmandu::Store::File::Memory::Bag> contains all "files" available in a
L<Catmandu::Store::File::Memory> FileStore "folder". All methods of L<Catmandu::Bag>,
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

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=item L<Catmandu::Droppable>

=back

=cut
