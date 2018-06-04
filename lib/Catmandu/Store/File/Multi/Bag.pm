package Catmandu::Store::File::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.09';

use Moo;
use Catmandu::Util qw(:is);
use Catmandu::Logger;
use namespace::clean;

extends 'Catmandu::Store::Multi::Bag';

with 'Catmandu::FileBag';

sub add {
    my ($self, $data) = @_;

    # Overwrite the Multi::Bag add an store each stream in the backend store

    my $rewind = 0;
    my $id     = $data->{_id};
    my $stream = $data->{_stream};

    my $new_data = {};

    # By default try to add the data to all the stores
    for my $store (@{$self->store->stores}) {
        my $bag = $store->bag($self->name);
        next unless $bag;

        if ($rewind) {

            # Rewind the stream after first use...
            Catmandu::BadVal->throw("IO stream needs to seekable")
                unless $stream->isa('IO::Seekable');
            $stream->seek(0, 0);
        }

        my $file = {_id => $id, _stream => $stream};
        $bag->add($file);

        for (keys %$file) {
            $new_data->{$_} = $file->{$_} unless exists $new_data->{$_};
        }

        $rewind = 1;
    }

    # Check if the returned record contains the minimum required fields
    # (otherwise we have a File::Store implementation that doesn't inline
    # update the passed $data in add($data))
    if (   exists $new_data->{size}
        && exists $new_data->{created}
        && exists $new_data->{modified})
    {
        # all is ok
    }
    else {
        $self->log->warn(
            "$self doesn't inline update \$data in add(\$data) method");
        $new_data = $self->get($id);
    }

    if ($new_data) {
        $data->{$_} = $new_data->{$_} for keys %$new_data;
    }
    else {
        $self->log->error("can't find $id in $self!");
    }

    1;
}

sub upload {
    my ($self, $io, $id) = @_;

    # Upload in a FileStore should send data, in a normal Store it adds an
    # empty record

    my $rewind;

    my $bytes = 0;

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
            $bytes
                = $store->bag($self->name)->upload($io, $id)
                || $self->log->error(
                "failed to upload $id to " . $self->name);
            $rewind = 1;
        }
        else {
            my $bag = $store->bag($self->name);
            next unless $bag;
            $bag->add({_id => $id});
        }
    }

    return $bytes;
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
