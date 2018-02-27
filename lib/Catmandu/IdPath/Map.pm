package Catmandu::IdPath::Map;

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
use File::Path;
use Catmandu::Error;
use namespace::clean;

with "Catmandu::IdPath";

has base_dir => (
    is => "ro",
    isa => sub { check_string( $_[0] ); },
    required => 1,
    coerce => sub { Cwd::abs_path( $_[0] ); }
);
has lookup_store => (
    is => "ro"
);
has lookup_bag => (
    is => "ro"
);
has lookup => (
    is => "ro",
    isa => sub {
        my $l = $_[0];
        #check_instance( $l, "Catmandu::Bag" ) returns false ..
        check_instance( $l );
        $l->does( "Catmandu::Bag" ) or die( "lookup should be Catmandu::Bag implementation" );
    },
    lazy => 1,
    builder => "_build_lookup"
);

sub _build_lookup {

    my $self = $_[0];

    Catmandu->store( $self->lookup_store )->bag( $self->lookup_bag );

}

sub is_valid_mapping {

    my $map = $_[0];

    return unless is_hash_ref( $map );

    is_string( $map->{_id} ) && is_string( $map->{_path} );

}

sub to_path {

    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need id" ) unless is_string( $id );

    if ( my $mapping = $self->lookup()->get( $id ) ) {

        return unless is_valid_mapping( $mapping );

        return $mapping->{_path};

    }

    my $md5 = Digest::MD5::md5_hex( $id );

    my $path = File::Spec->catdir(
        $self->base_dir(),
        POSIX::strftime(
            "%Y/%m/%d/%H/%M/%S", gmtime(time)
        ),
        $md5
    );

    $self->lookup()->add( { _id => $id, _path => $path } );

    $path;

}

sub from_path {

    my ( $self, $path ) = @_;

    my $mapping = $self->lookup()->select( _path => $path )->first();

    return unless defined $mapping;

    return $mapping->{_id};

}

sub delete {

    my ( $self, $id ) = @_;

    my $path = $self->to_path( $id );

    my $err;
    File::Path::rmtree( $path, { error => $err } );

    if ( @$err ) {

        my @messages;

        for my $diag ( @$err ) {

            my ( $file, $message ) = %$diag;
            push @messages, $message;

        }

        Catmandu::Error->throw( join( ",", @messages ) );

    }

    $self->lookup()->delete( $id );

}

sub generator {

    my $self = $_[0];

    return sub {

        state $gen = $self->lookup()->generator();

        my $mapping = $gen->();

        return unless defined $mapping;

        Catmandu::BadArg->throw( "invalid mapping detected" . Dumper($mapping) )
            unless is_valid_mapping( $mapping );

        +{ _id => $mapping->{_id}, _path => $mapping->{_path} };

    };

}

1;

__END__

=pod

=head1 NAME

Catmandu::IdPath::Map - translates between id and path using a bag as lookup

=head1 SYNOPSIS

    use Catmandu::IdPath::Map;
    use Catmandu::Store::DBI;

    # Bag to store/retrieve all path -> directory mapping
    my $bag = Catmandu::Store::DBI->new(
        data_source => "dbi:sqlite:dbname=/data/index.db"
    )->bag("paths");

    my $p = Catmandu::IdPath::Map->new(
        base_dir => "/data",
        lookup => $lookup
    );

    # Returns a path like: "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661"
    my $path = $p->to_path("a");

    # Translates $path back to the id: "a"
    my $id = $p->from_path( $path );

    # Catmandu::IdPath::Map is a Catmandu::Iterable
    # Returns list of records: [{ _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }]
    my $id_paths = $p->to_array();

=head1 DESCRIPTION

    This package uses a Catmandu::Bag backend to translate between ids and paths.

    Each record looks like this:

        { _id => "a", _path => "/data/2018/01/01/16/00/00/0cc175b9c0f1b6a831c399e269772661" }

    If the mapping for the id does not exist yet, the method to_path calculates it by appending these variables:

    * $base_dir which is configurable
    * $Y: current year
    * $M: current month
    * $D: current day of month
    * $h: current hour
    * $m: current minute
    * $s: current second
    * $md5_id: the md5 of the _id

    Every call to C<to_path> will generate a directory entry in the backend database,
    if it didn't already exist.

=head1 METHODS

=head2 new( OPTIONS )

Create a new Catmandu::IdPath::Map with the following configuration
parameters:

=over

=item base_dir

The base directory where the files are stored. Required

=item lookup_store

Name of the store in the Catmandu configuration.

Ignored when lookup is provided (see below).

=item lookup_bag

Name of the bag.

Ignored when lookup is provided (see below).

=item lookup

Catmandu::Bag instance that does the lookup.

If not provided the lookup defaults to:

    Catmandu->store( $self->lookup_store )->bag( $self->lookup_bag );

=back

=head1 INHERITED METHODS

This Catmandu::IdPath::Map implements:

=over 3

=item L<Catmandu::IdPath>

=back

=head1 SEE ALSO

L<Catmandu::IdPath>

=cut
