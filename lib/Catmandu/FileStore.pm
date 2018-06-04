package Catmandu::FileStore;

our $VERSION = '1.09';

use Catmandu::Sane;
use Moo::Role;
use Catmandu::Util;
use namespace::clean;

with 'Catmandu::Store';

has index_bag   => (is => 'ro', default => sub {'index'},);
has index_class => (is => 'ro', default => sub {ref($_[0]) . '::Index'},);
has index       => (is => 'lazy');

sub _build_default_bag {
    $_[0]->index_bag;
}

sub _build_index {
    my ($self) = @_;
    my $name = $self->index_bag;
    my $inst;

    try {
        my $opts         = {store => $self, name => $name};
        my $default_opts = $self->default_options;
        my $bag_opts     = $self->bag_options->{$name} //= {};
        $opts = {%$default_opts, %$bag_opts, %$opts};

        my $pkg        = Catmandu::Util::require_package($self->index_class);
        my $index_name = $self->index_bag;

        my $default_plugins = $self->default_plugins;
        my $plugins = delete($opts->{plugins}) // [];

        if (@$default_plugins || @$plugins) {
            $pkg = $pkg->with_plugins(@$default_plugins, @$plugins);
        }

        $inst = $pkg->new(%$opts);
    }
    catch {
        $self->log->warn(
            "no instance of " . $self->index_class . " created : $_");
    };

    $inst;
}

sub bag {
    my $self       = shift;
    my $name       = shift // $self->index_bag;
    my $index_name = $self->index_bag;

    # Return the index when requested
    if ($name eq $index_name) {
        $self->index;
    }

    # Otherwise load the container for files
    elsif ($self->index->exists($name)) {
        my $opts         = {store => $self, name => $name};
        my $default_opts = $self->default_options;
        my $bag_opts     = $self->bag_options->{$name} //= {};
        $opts = {%$default_opts, %$bag_opts, %$opts};
        my $pkg = Catmandu::Util::require_package(delete($opts->{class})
                // $self->bag_class);

        my $default_plugins = $self->default_plugins;
        my $plugins = delete($opts->{plugins}) // [];

        if (@$default_plugins || @$plugins) {
            $pkg = $pkg->with_plugins(@$default_plugins, @$plugins);
        }

        $pkg->new(%$opts);
    }
    else {
        return undef;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::FileStore - Namespace for packages that can make files persistent

=head1 SYNOPSIS

    # From the command line

    # Export a list of all file containers
    $ catmandu export File::Simple --root t/data to YAML

    # Export a list of all files in container '1234'
    $ catmandu export File::Simple --root t/data --bag 1234 to YAML

    # Add a file to the container '1234'
    $ catmandu stream /tmp/myfile.txt to File::Simple --root t/data --bag 1234 --id myfile.txt

    # Download the file 'myfile.txt' from the container '1234'
    $ catmandu stream File::Simple --root t/data --bag 1234 --id myfile.txt to /tmp/output.txt

    # Delete the file 'myfile.txt' from the container '1234'
    $ catmandu delete File::Simple --root t/data --bag 1234 --id myfile.txt

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('File::Simple' , root => 't/data');

    # List all containers
    $store->index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new container
    $store->index->add({ _id => '1234' });

    # Get the container
    my $files = $store->index->files('1234');

    # Add a file to the container
    $files->upload(IO::File->new('<foobar.txt'), 'foobar.txt');

    my $file = $files->get('foobar.txt');

    # Stream the contents of a file
    $files->stream(IO::File->new('>foobar.txt'), $file);

    # Delete a file
    $files->delete('foobar.txt');

    # Delete a container
    $store->index->delete('1234');

=head1 DESCRIPTION

Each L<Catmandu::FileStore> is a L<Catmandu::Store> and inherits all its methods,

A L<Catmandu::FileStore> is package to store and retrieve binary content in
an filesystem, memory or a network. A C<Catmandu::FileStore> contains one or more
C<Catmandu::FileBag> which is a kind of folder.

Each C<Catmandu::FileBag> contains one or more files.

One special C<Catmandu::FileBag> is the C<index> and contains the listing
of all C<Catmandu::FileBag> in the C<Catmandu::FileStore>.

=head1 CONFIGURATION

=over

=item index_bag

The name of the index bag to use when no bag name is give. The index bag is a
bag containing a listing of all C<Catmandu::FileBag>-s in the Store.

    my $index = $store->index;

    $index->each(sub {
        my $bag = shift;

        printf "%s\n" , $bag->{_id};
    });

=item index_class

The default class implementation to use for an index of C<Catmandu::FileBag>-s.
By default this is the C<Catmandu::FileStore> implementation with '::Index' added.

=back

=head1 METHODS

=head2 bag($name)

Create or retieve a bag with name C<$name>. Returns a L<Catmandu::FileBag>.

=head2 index

Returns the index  L<Catmandu::FileBag> for the L<Catmandu::FileStore>.

  my $index = $store->index;

  # Add a new file container
  $index->add({ _id => '1234'});

  # Anf use it...
  my $container = $store->bag('1234');

  $container->upload(IO::File->new('data.txt') , 'data.txt');

=head2 log

Return the current logger. Can be used when creating your own Stores.

E.g.

    package Catmandu::Store::Hash;

    ...

    sub generator {
        my ($self) = @_;

        $self->log->debug("generating record");
        ...
    }

See also: L<Catmandu> for activating the logger in your main code.

=head1 SEE ALSO

L<Catmandu::Store::File::Simple>,
L<Catmandu::Store::File::Memory>,
L<Catmandu::FileBag>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
