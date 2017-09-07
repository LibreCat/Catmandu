package Catmandu::Store::File::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.0603';

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

=head1 INHERITED METHODS

This Catmandu::Bag implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::FileBag>

=item L<Catmandu::Droppable>

=back

=cut
