package Catmandu::Path::Number;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Path::Tiny;
use Path::Iterator::Rule;
use File::Spec;
use Carp;
use Catmandu::BadArg;
use namespace::clean;

with "Catmandu::Path";

has keysize => (is => 'ro', default  => 9, trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3"
        unless $self->keysize % 3 == 0;
}
#do not allow zero padded numbers
sub is_valid_id {
    my $id = $_[0];
    return 0 unless is_natural($id);
    my $new_id = int($id);
    "$new_id" eq "$id";
}

sub to_path {

    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need valid natural number" ) unless is_valid_id( $id );

    my $keysize = $self->keysize();
    my $id_formatted = sprintf "%-${keysize}.${keysize}d", $id;

    Catmandu::BadArg->throw( "id $id too long to fit into ".$self->keysize()." characters")
        if length($id_formatted) > $keysize;

    File::Spec->catdir(
        $self->base_dir, unpack( "(A3)*", $id_formatted )
    );

}

sub from_path {

    my ( $self, $path ) = @_;

    my @split_path = File::Spec->splitdir( $path );
    my $id = join( "", splice(@split_path, scalar(File::Spec->splitdir( $self->base_dir )) ) );

    is_natural($id) ? int($id) : undef;

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

        croak "$base_dir is not number based directory" unless defined( $id );

        +{ _id => $id, _path => $path };
    };

}

1;

__END__

=pod

=head1 NAME

Catmandu::Path::Number - A number based path translator

=head1 SYNOPSIS

    use Catmandu::Path::Number;

    my $p = Catmandu::Path::Number->new(
        base_dir => "/data",
        keysize => 9
    );

    #get path for record: "/data/000/001/234"
    my $path = $p->to_path(1234);

    #translate $path back to 1234
    my $id = $p->from_path( $path );

    #Catmandu::Path::Number is a Catmandu::Iterable
    #Returns list of records: [{ _id => 1234, _path => "/data/000/001/234" }]
    my $id_paths = $p->to_array();

=head1 METHODS

=head2 new( base_dir => $path , keysize => NUM )

Create a new Catmandu::Path::Number with the following configuration
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

This Catmandu::Path::Number implements:

=over 3

=item L<Catmandu::Path>

=back

=head1 SEE ALSO

L<Catmandu::Path>

=cut
