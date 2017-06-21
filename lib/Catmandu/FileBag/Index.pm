package Catmandu::FileBag::Index;

our $VERSION = '1.0601';

use Catmandu::Sane;
use Moo::Role;
use IO::String;
use utf8;
use Catmandu::Util qw(:check);
use namespace::clean;

sub files {
    my ($self, $id) = @_;
    return $self->store->bag($id);
}

1;

__END__

=pod

=head1 NAME

Catmandu::FileBag::Index - Flag a Bag as a FileStore Index

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('Simple' , root => 't/data');

    # List all containers
    $store->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $store->bag->add({ _id => '1234' });

    # Get the v
    my $files = $store->bag->files('1234');

    # Add a file to the files
    $files->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Stream the contents of a file
    $files->stream(IO::File->new('>foobar.txt'), 'foobar.txt');

    # Delete a file
    $files->delete('foobar.txt');

    # Delete a folder
    $store->bag->delete('1234');


=head1 DESCRIPTION

Each L<Catmandu::FileBag> is a L<Catmandu::Bag> and inherits all its methods.

=head1 METHODS

=head2 files($id)

Return the L<Catmandu::FileBag> for this L<Catmandu::FileStore> containing
all the files

=head1 SEE ALSO

L<Catmandu::FileStore> ,
L<Catmandu::FileBag>

=cut
