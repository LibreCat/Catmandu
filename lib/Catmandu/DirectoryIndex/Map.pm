package Catmandu::DirectoryIndex::Map;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Catmandu;
use Cwd;
use File::Spec;
use Catmandu::BadArg;
use Catmandu::Error;
use Digest::MD5 qw();
use POSIX qw();
use Data::Dumper;
use Moo;
use Path::Tiny qw(path);
use namespace::clean;

with "Catmandu::DirectoryIndex";

has store_name => (is => "ro");

has bag_name => (is => "ro");

has bag => (
    is  => "ro",
    isa => sub {
        my $l = $_[0];

        #check_instance( $l, "Catmandu::Bag" ) returns false ..
        check_instance($l);
        $l->does("Catmandu::Bag")
            or die("lookup should be Catmandu::Bag implementation");
    },
    lazy    => 1,
    builder => "_build_bag"
);

sub _build_bag {
    Catmandu->store($_[0]->store_name)->bag($_[0]->bag_name);
}

#checks whether mapping record is syntactically correct
sub _is_valid_mapping {
    my $map = $_[0];

    return unless is_hash_ref($map);

    is_string($map->{_id}) && is_string($map->{_path});
}

#creates new directory: returns path if all is ok, throws an error on failure
sub _new_path {
    my ($self, $id) = @_;

    Catmandu::BadArg->throw("need id") unless is_string($id);

    my $md5 = Digest::MD5::md5_hex($id);

    my $path = File::Spec->catdir($self->base_dir(),
        POSIX::strftime("%Y/%m/%d/%H/%M/%S", gmtime(time)), $md5);

    my $err;
    path($path)->mkpath({error => \$err});

    Catmandu::Error->throw(
        "unable to create directory $path: " . Dumper($err))
        if defined($err) && scalar(@$err);

    $self->bag()->add({_id => $id, _path => $path});

    $path;
}

#translates id to path: return either valid path or undef.
sub _to_path {
    my ($self, $id) = @_;

    Catmandu::BadArg->throw("need id") unless is_string($id);

    my $mapping = $self->bag()->get($id);

    #no mapping, no path
    return unless _is_valid_mapping($mapping);

    #inconsistent behaviour: mapping exists, but directory is gone
    Catmandu::Error->throw("mapping $id contains non existant directory")
        unless -d $mapping->{_path};

    $mapping->{_path};
}

sub get {
    my ($self, $id) = @_;

    my $path = $self->_to_path($id);

    is_string($path) ? {_id => $id, _path => $path} : undef;
}

sub add {
    my ($self, $id) = @_;

    my $path = $self->_to_path($id) || $self->_new_path($id);

    {_id => $id, _path => $path};
}

sub delete {
    my ($self, $id) = @_;

    my $path = $self->_to_path($id);

    if (is_string($path)) {

        my $err;
        path($path)->remove_tree({error => \$err});

        Catmandu::Error->throw(
            "unable to remove directory $path: " . Dumper($err))
            if defined($err) && scalar(@$err);

    }

    $self->bag()->delete($id);
}

sub delete_all {
    my $self = $_[0];

    if (-d $self->base_dir) {

        my $err;
        path($self->base_dir)->remove_tree({keep_root => 1, error => \$err});

        Catmandu::Error->throw("unable to remove entries from base directory "
                . $self->base_dir . " : "
                . Dumper($err))
            if defined($err) && scalar(@$err);

    }

    $self->bag->delete_all;
}

sub generator {
    my $self = $_[0];

    return sub {
        state $gen = $self->bag()->generator();

        my $mapping = $gen->();

        return unless defined $mapping;

        Catmandu::Error->throw(
            "invalid mapping detected: " . Dumper($mapping))
            unless _is_valid_mapping($mapping);

        Catmandu::Error->throw(
            "mapping $mapping->{_id} contains non existant directory")
            unless -d $mapping->{_path};

        +{_id => $mapping->{_id}, _path => $mapping->{_path}};
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::DirectoryIndex::Map - translates between id and path using a Catmandu::Bag as lookup

=head1 SYNOPSIS

    use Catmandu::DirectoryIndex::Map;
    use Catmandu::Store::DBI;

    # Bag to store/retrieve all path -> directory mapping
    my $bag = Catmandu::Store::DBI->new(
        data_source => "dbi:sqlite:dbname=/data/index.db"
    )->bag("paths");

    my $p = Catmandu::DirectoryIndex::Map->new(
        base_dir => "/data",
        bag => $bag
    );

    # Tries to find a mapping for id "a".
    # return: mapping or undef
    my $mapping = $p->get("a");

    # Returns a mapping like { _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }
    my $mapping = $p->add("a");

    # Catmandu::DirectoryIndex::Map is a Catmandu::Iterable
    # Returns list of records: [{ _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }]
    my $mappings = $p->to_array();

=head1 DESCRIPTION

    This package uses a Catmandu::Bag backend to translate between ids and paths.

    Each record looks like this:

        { _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }

    If the mapping for the id does not exist yet, this package calculates it by concatenating
    into a path:

    * $base_dir which is configurable
    * YYYY: current year
    * MM: current month
    * DD: current day of month
    * HH: current hour
    * MM: current minute
    * SS: current second
    * TEXT: the md5 of the _id

    Every call to C<add> will generate a directory entry in the backend database,
    if it didn't already exist.

=head1 METHODS

=head2 new( OPTIONS )

Create a new Catmandu::DirectoryIndex::Map with the following configuration
parameters:

=over

=item base_dir

See L<Catmandu::DirectoryIndex>

=item store_name

Name of the store in the Catmandu configuration.

Ignored when bag instance is given.

=item bag_name

Name of the bag in the Catmandu configuration.

Ignored when bag instance is given

=item bag

Instance of L<Catmandu::Bag> where all mappings between _id and _path are stored.

=back

=head1 INHERITED METHODS

This Catmandu::DirectoryIndex::Map implements:

=over 3

=item L<Catmandu::DirectoryIndex>

=back

=head1 SEE ALSO

L<Catmandu::DirectoryIndex>

=cut
