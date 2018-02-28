package Catmandu::PathIndex::Map;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Catmandu;
use Cwd;
use File::Spec;
use Catmandu::BadArg;
use Digest::MD5 qw();
use POSIX qw();
use Data::Dumper;
use Moo;
use Path::Tiny qw(path);
use Catmandu::Error;
use namespace::clean;

with "Catmandu::PathIndex";

has base_dir => (
    is => "ro",
    isa => sub { check_string( $_[0] ); },
    required => 1,
    coerce => sub { Cwd::abs_path( $_[0] ); }
);
has store_name => (
    is => "ro"
);
has bag_name => (
    is => "ro"
);
has bag => (
    is => "ro",
    isa => sub {
        my $l = $_[0];
        #check_instance( $l, "Catmandu::Bag" ) returns false ..
        check_instance( $l );
        $l->does( "Catmandu::Bag" ) or die( "lookup should be Catmandu::Bag implementation" );
    },
    lazy => 1,
    builder => "_build_bag"
);

sub _build_bag {
    my $self = $_[0];

    Catmandu->store( $self->store_name )->bag( $self->bag_name );
}

sub _is_valid_mapping {
    my $map = $_[0];

    return unless is_hash_ref( $map );

    is_string( $map->{_id} ) && is_string( $map->{_path} );
}

sub _new_path {
    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need id" ) unless is_string( $id );

    my $md5 = Digest::MD5::md5_hex( $id );

    my $path = File::Spec->catdir(
        $self->base_dir(),
        POSIX::strftime(
            "%Y/%m/%d/%H/%M/%S", gmtime(time)
        ),
        $md5
    );

    $self->bag()->add( { _id => $id, _path => $path } );

    $path;
}

sub _to_path {
    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need id" ) unless is_string( $id );

    my $mapping = $self->bag()->get( $id );

    return unless _is_valid_mapping( $mapping );

    $mapping->{_path};
}

sub get {
    my ( $self, $id ) = @_;

    my $path = $self->_to_path( $id );

    is_string( $path ) && -d $path ? { _id => $id, _path => $path } : undef;
}

sub add {
    my ( $self, $id ) = @_;

    my $path = $self->_to_path( $id ) || $self->_new_path( $id );

    path( $path )->mkpath( $path ) unless -d $path;

    { _id => $id, _path => $path };
}

sub delete {
    my ( $self, $id ) = @_;

    my $path = $self->_to_path( $id );

    if ( is_string( $path ) && -d $path ) {
        path( $path )->remove_tree;
    }

    $self->bag()->delete( $id );
}

sub delete_all {
    my $self = $_[0];

    path( $self->base_dir )->remove_tree({ keep_root => 1 });
    $self->bag->delete_all;
}

sub generator {
    my $self = $_[0];

    return sub {
        state $gen = $self->bag()->generator();

        my $mapping = $gen->();

        return unless defined $mapping;

        Catmandu::BadArg->throw( "invalid mapping detected" . Dumper($mapping) )
            unless _is_valid_mapping( $mapping );

        +{ _id => $mapping->{_id}, _path => $mapping->{_path} };
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::PathIndex::Map - translates between id and path using a bag as lookup

=head1 SYNOPSIS

    use Catmandu::PathIndex::Map;
    use Catmandu::Store::DBI;

    # Bag to store/retrieve all path -> directory mapping
    my $bag = Catmandu::Store::DBI->new(
        data_source => "dbi:sqlite:dbname=/data/index.db"
    )->bag("paths");

    my $p = Catmandu::PathIndex::Map->new(
        base_dir => "/data",
        bag => $bag
    );

    # Tries to find a mapping for id "a".
    # return: mapping or undef
    my $mapping = $p->get("a");

    # Returns a mapping like { _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }
    my $mapping = $p->add("a");

    # Catmandu::PathIndex::Map is a Catmandu::Iterable
    # Returns list of records: [{ _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }]
    my $mappings = $p->to_array();

=head1 DESCRIPTION

    This package uses a Catmandu::Bag backend to translate between ids and paths.

    Each record looks like this:

        { _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }

    If the mapping for the id does not exist yet, this package calculates it by appending these variables:

    * $base_dir which is configurable
    * $Y: current year
    * $M: current month
    * $D: current day of month
    * $h: current hour
    * $m: current minute
    * $s: current second
    * $md5_id: the md5 of the _id

    Every call to C<add> will generate a directory entry in the backend database,
    if it didn't already exist.

=head1 METHODS

=head2 new( OPTIONS )

Create a new Catmandu::PathIndex::Map with the following configuration
parameters:

=over

=item base_dir

The base directory where the files are stored. Required

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

This Catmandu::PathIndex::Map implements:

=over 3

=item L<Catmandu::PathIndex>

=back

=head1 SEE ALSO

L<Catmandu::PathIndex>

=cut
