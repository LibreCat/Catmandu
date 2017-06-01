package Catmandu::FileStore::Bag;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo::Role;
use IO::String;
use utf8;
use Catmandu::Util qw(:check);
use namespace::clean;

with 'Catmandu::Bag';

sub stream {
    my ($self,$io,$data) = @_;
    check_hash_ref($data);
    check_invocant($io);
    $data->{_stream}->($io);
}

sub as_string {
    my ($self,$data) = @_;
    check_hash_ref($data);
    my $str;
    my $io = IO::String->new($str);
    $data->{_stream}->($io);
    $str;
}

sub as_string_utf8 {
    my ($self,$data) = @_;
    check_hash_ref($data);
    my $str;
    my $io = IO::String->new($str);
    $data->{_stream}->($io);
    utf8::decode($str);
    $str;
}

sub upload {
    my ($self,$io,$id) = @_;
    check_string($id);
    check_invocant($io);
    $self->add({ _id => $id , _stream => $io});
}

1;

__END__

=pod

=head1 NAME

Catmandu::FileStore::Bag - A Catmandu::FileStore compartment to persist binary data

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('Simple' , root => 't/data');

    # List all containers
    $store->bag->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new container
    $store->bag->add({ _id => '1234' });

    # Get the container
    my $container = $store->bag('1234');

    # Add a file to the container
    $container->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    # Stream the contents of a file
    $container->stream(IO::File->new('>foobar.txt'), 'foobar.txt');

    # Delete a file
    $container->delete('foobar.txt');

    # Delete a container
    $store->bag->delete('1234');


=head1 DESCRIPTION

Each L<Catmandu::FileStore::Bag> is a L<Catmandu::Bag> and inherits all its methods.

=head1 CONFIGURATION

=over

=item fix

Contains an array of fixes (or Fix files) to be applied before importing data into the bag.

=item plugins

An array of Catmandu::Pluggable to apply to the bag items.

=back

=head1 METHODS

=head2 add($hash)

Add data to the L<Catmandu::FileStore::Bag>. Each $hash should contain two keys:

    _id     : the 'filename' of the content to store
    _stream : an IO::Handle with the binary content of the file

=head2 add_many($array)

=head2 add_many($iterator)

Add or update one or more items to the bag.

=head2 upload($io, $file_name)

An helper application to add an IO::Handle $io to the L<Catmandu::FileStore::Bag>

=head2 stream($io, $file)

A helper application to stream the contents of a L<Catmandu::FileStore::Bag> item
to an IO::Handle.

=head2 get($id)

Retrieves the item with identifier $id from the bag.

=head2 as_string($file)

Return the contents of the L<Catmandu::FileStore::Bag> item as a string.

=head2 as_string_utf8($file)

Return the contents of the L<Catmandu::FileStore::Bag> item as an UTF-8 string.

=head2 exists($id)

Returns C<1> if the item with identifier $id exists in the bag.

=head2 get_or_add($id, $hash)

Retrieves the item with identifier $id from the store or adds C<$hash> with _id
C<$id> if it's not found.

=head2 delete($id)

Deletes the item with C<$id> from the bag.

=head2 delete_all

Clear the bag.

=head2 commit

Commit changes.

=head2 log

Return the current logger.

=head1 CLASS METHODS

=head2 with_plugins($plugin)

=head2 with_plugins(\@plugins)

Plugins are a kind of fixes that should be available for each bag. E.g. the Datestamps plugin will
automatically store into each bag item the fields 'date_updated' and 'date_created'. The with_plugins
accept one or an array of plugin classnames and returns a subclass of the Bag with the plugin
methods implemented.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Fix>, L<Catmandu::Pluggable>

=cut
