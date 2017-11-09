package Catmandu::Store::File::Memory;

our $VERSION = '1.07';

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu::Store::File::Memory::Index;
use Catmandu::Store::File::Memory::Bag;
use namespace::clean;

with 'Catmandu::FileStore';
with 'Catmandu::Droppable';

has _files => (is => 'ro', lazy => 1, default => sub {+{}});

sub drop {
    my ($self) = @_;

    $self->index->delete_all;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::Memory - A Catmandu::FileStore to keep files in memory

=head1 SYNOPSIS

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('File::Mempory');

    my $index = $store->index;

    # List all folders
    $index->each(sub {
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

    # Delete a container
    $index->delete('1234');

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

L<Catmandu::Store::File::Memory::Index>,
L<Catmandu::Store::File::Memory::Bag>,
L<Catmandu::Plugin::SideCar>,
L<Catmandu::FileStore>
=cut
