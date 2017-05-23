package Catmandu::Store::Simple::Index;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo;
use Path::Tiny;
use Carp;
use namespace::clean;

use Data::Dumper;

with 'Catmandu::FileStore::Bag';

sub generator {
    my ($self) = @_;

    my $root = $self->store->root;

    unless (-d $root) {
        $self->log->error("no root $root found");
        return sub {undef};
    }

    $self->log->debug("creating generator for root: $root");
    return sub {
        state $io;

        unless (defined($io)) {
            open($io, "find -L $root -mindepth 3 -maxdepth 4 -type d|");
        }

        my $line = <$io>;

        unless (defined($line)) {
            close($io);
            return undef;
        }

        chop($line);
        $line =~ s/$root//;
        $line =~ s/\///g;
        $line =~ s/^0+//;
        +{ _id => $line };
    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    $self->log->debug("Checking exists $id");

    my $path = $self->store->path_string($id);

    -d $path;
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id  = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    my $path = $self->store->path_string($id);

    unless (defined $path) {
        my $err = "Failed to create path from $id need a number of max " . $self->store->keysize . " digits";
        $self->log->error($err);
        Catmandu::BadArg->throw($err);
    }

    $self->log->debug("Generating path $path for key $id");

    # Throws an exception when the path can't be created
    path($path)->mkpath;

    return $self->get($id);
}

sub get {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $path = $self->store->path_string($id);

    unless ($path) {
        $self->log->error("Failed to create path from $id need a number of max " . $self->store->keysize . " digits");
        return undef;
    }

    $self->log->debug("Loading path $path for id $id");

    return undef unless -d $path;

    my @stat = stat $path;

    return +{
        _id      => $id ,
        created  => $stat[10],
        modified => $stat[9],
    };
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

    $self->each(sub {
        my $key = shift->{_id};
        $self->delete($key);
    });
}

sub commit {
    return 1;
}

1;
