package Catmandu::IdPath::Number;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;
use Cwd;
use Path::Tiny;
use Path::Iterator::Rule;
use File::Spec;
use Carp;
use Catmandu::BadArg;
use namespace::clean;

with "Catmandu::IdPath";

has base_dir => (
    is => "ro",
    isa => sub { check_string( $_[0] ); },
    required => 1,
    coerce => sub { Cwd::abs_path( $_[0] ); }
);

has keysize => (is => 'ro', default  => 9, trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3"
        unless $self->keysize % 3 == 0;
}
sub format_id {
    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need natural number" )
        unless is_natural( $id );

    my $n_id = int( $id );

    Catmandu::BadArg->throw( "id must be bigger or equal to zero" )
        if $n_id < 0;

    my $keysize = $self->keysize();

    Catmandu::BadArg->throw( "id '$id' does not fit into configured keysize $keysize" )
        if length( "$id" ) > $keysize;

    sprintf "%-${keysize}.${keysize}d", $n_id;

}

sub to_path {

    my ( $self, $id ) = @_;

    my $f_id = $self->format_id( $id );

    File::Spec->catdir(
        $self->base_dir, unpack( "(A3)*", $f_id )
    );

}

sub from_path {

    my ( $self, $path ) = @_;

    my @split_path = File::Spec->splitdir( $path );
    my $id = join( "", splice(@split_path, scalar(File::Spec->splitdir( $self->base_dir )) ) );

    $self->format_id( $id );

}

sub generator {

    my $self = $_[0];

    return sub {

        state $rule;
        state $iter;
        state $base_dir = $self->base_dir();

        unless ( $iter ) {

            $rule = Path::Iterator::Rule->new();
            $rule->min_depth( $self->keysize() / 3 );
            $rule->max_depth( $self->keysize() / 3 );
            $rule->directory();
            $iter = $rule->iter( $base_dir , { depthfirst => 1 } );

        }

        my $path = $iter->();

        return unless defined $path;

        my $id = $self->from_path( $path );

        +{ _id => $id, _path => $path };
    };

}

1;

__END__

=pod

=head1 NAME

Catmandu::IdPath::Number - A number based path translator

=head1 SYNOPSIS

    use Catmandu::IdPath::Number;

    my $p = Catmandu::IdPath::Number->new(
        base_dir => "/data",
        keysize => 9
    );

    # Return path like record: "/data/000/001/234"
    my $path = $p->to_path(1234);

    # Translates $path back to "000001234"
    my $id = $p->from_path( $path );

    # Catmandu::IdPath::Number is a Catmandu::Iterable
    # Returns list of records: [{ _id => "000001234", _path => "/data/000/001/234" }]
    my $id_paths = $p->to_array();

=head1 METHODS

=head2 new( base_dir => $path , keysize => NUM )

Create a new Catmandu::IdPath::Number with the following configuration
parameters:

=over

=item base_dir

The base directory where the files are stored. Required

=item keysize

By default the directory structure is 3 levels deep. With the keysize option
a deeper nesting can be created. The keysize needs to be a multiple of 3.
All the container keys of a L<Catmandu::Store::File::Simple> must be integers.

=back

=head1 INHERITED METHODS

This Catmandu::IdPath::Number implements:

=over 3

=item L<Catmandu::IdPath>

=back

=head1 SEE ALSO

L<Catmandu::IdPath>

=cut
