package Catmandu::FileBag;

our $VERSION = '1.0606';

use Catmandu::Sane;
use IO::String;
use Catmandu::Util qw(:check);
use Moo::Role;
use namespace::clean;

sub stream {
    my ($self, $io, $data) = @_;
    check_hash_ref($data);
    check_invocant($io);
    $data->{_stream}->($io);
}

sub as_string {
    my ($self, $data) = @_;
    check_hash_ref($data);
    my $str;
    my $io = IO::String->new($str);
    $data->{_stream}->($io);
    $str;
}

sub as_string_utf8 {
    my ($self, $data) = @_;
    check_hash_ref($data);
    my $str;
    my $io = IO::String->new($str);
    $data->{_stream}->($io);
    utf8::decode($str);
    $str;
}

sub upload {
    my ($self, $io, $id) = @_;
    check_string($id);
    check_invocant($io);
    $self->add({_id => $id, _stream => $io});
}

1;

__END__

=pod

=head1 NAME

Catmandu::FileBag - A Catmandu::FileStore compartment to persist binary data

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

    # Get the files
    my $files = $store->bag->files('1234');

    # Add a file to the files
    $files->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Stream the contents of a file
    my $file = $files->get('foobar.txt');
    $files->stream(IO::File->new('>foobar.txt'), $file);

    # Delete a file
    $files->delete('foobar.txt');

    # Delete a folder
    $store->index->delete('1234');


=head1 DESCRIPTION

Each L<Catmandu::FileBag> is a L<Catmandu::Bag> and inherits all its methods.

=head1 METHODS

=head2 upload($io, $file_name)

An helper application to add an IO::Handle $io to the L<Catmandu::FileBag>. Returns
the number of bytes written.

=head2 stream($io, $file)

A helper application to stream the contents of a L<Catmandu::FileBag> item
to an IO::Handle. Returns the nuber of bytes written.

=head2 as_string($file)

Return the contents of the L<Catmandu::FileBag> item as a string.

=head2 as_string_utf8($file)

Return the contents of the L<Catmandu::FileBag> item as an UTF-8 string.

=head1 SEE ALSO

L<Catmandu::FileStore> ,
L<Catmandu::FileBag::Index>

=cut
