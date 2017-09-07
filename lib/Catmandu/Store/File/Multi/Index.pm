package Catmandu::Store::File::Multi::Index;

use Catmandu::Sane;

our $VERSION = '1.0603';

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

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag::Index>

=item L<Catmandu::Droppable>

=back

=cut
