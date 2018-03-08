package Catmandu::Store::File::Simple::Index;

our $VERSION = '1.09';

use Catmandu::Sane;
use Moo;
use Path::Tiny;
use Carp;
use POSIX qw(ceil);
use Path::Iterator::Rule;
use File::Spec;
use namespace::clean;

use Data::Dumper;

with 'Catmandu::Bag';
with 'Catmandu::FileBag::Index';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $root       = $self->store->root;
    my $keysize    = $self->store->keysize;
    my @root_split = File::Spec->splitdir($root);

    my $mindepth = ceil($keysize / 3);

    unless (-d $root) {
        $self->log->error("no root $root found");
        return sub {undef};
    }

    $self->log->debug("creating generator for root: $root");

    my $rule = Path::Iterator::Rule->new;
    $rule->min_depth($mindepth);
    $rule->max_depth($mindepth);
    $rule->directory;

    return sub {
        state $iter = $rule->iter($root, {depthfirst => 1});

        my $path = $iter->();

        return undef unless defined($path);

        # Strip of the root part and translate the path to an identifier
        my @split_path = File::Spec->splitdir($path);
        my $id = join("", splice(@split_path, int(@root_split)));

        unless ($self->store->uuid) {
            $id =~ s/^0+//;
        }

        $self->get($id);
    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    $self->log->debug("Checking exists $id");

    my $path = $self->store->path_string($id);

    defined($path) && -d $path;
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    my $path = $self->store->path_string($id);

    unless (defined $path) {
        my $err
            = "Failed to create path from $id need a number of max "
            . $self->store->keysize
            . " digits";
        $self->log->error($err);
        Catmandu::BadArg->throw($err);
    }

    $self->log->debug("Generating path $path for key $id");

    # Throws an exception when the path can't be created
    path($path)->mkpath;

    my $new_data = $self->get($id);

    $data->{$_} = $new_data->{$_} for keys %$new_data;

    1;
}

sub get {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $path = $self->store->path_string($id);

    unless ($path) {
        $self->log->error(
                  "Failed to create path from $id need a number of max "
                . $self->store->keysize
                . " digits");
        return undef;
    }

    $self->log->debug("Loading path $path for id $id");

    return undef unless -d $path;

    my @stat = stat $path;

    return +{_id => $id,};
}

sub delete {
    my ($self, $id) = @_;

    croak "Need a key" unless defined $id;

    my $path = $self->store->path_string($id);

    unless ($path) {
        $self->log->error("Failed to create path from $id");
        return undef;
    }

    $self->log->debug("Destoying path $path for key $id");

    return undef unless -d $path;

    # Throws an exception when the path can't be created
    path($path)->remove_tree;

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );
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
