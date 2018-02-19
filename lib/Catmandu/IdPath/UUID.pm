package Catmandu::IdPath::UUID;

our $VERSION = '1.08';

use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Moo;
use Cwd;
use Path::Tiny;
use Path::Iterator::Rule;
use File::Spec;
use Data::UUID;
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

sub is_uuid {

    my $id = $_[0];
    is_string( $id ) && $id =~ /^[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}$/o;

}

sub to_path {

    my ( $self, $id ) = @_;

    Catmandu::BadArg->throw( "need valid uuid" ) unless is_uuid( $id );

    File::Spec->catdir(
        $self->base_dir, unpack( "(A3)*", $id )
    );

}

sub from_path {

    my ( $self, $path ) = @_;

    my @split_path = File::Spec->splitdir( $path );
    my $id = join( "", splice(@split_path, scalar(File::Spec->splitdir( $self->base_dir )) ) );

    Catmandu::BadArg->throw( "invalid uuid detected: $id" ) unless is_uuid( $id );

    $id;

}

sub generator {

    my $self = $_[0];

    return sub {

        state $rule;
        state $iter;
        state $base_dir = $self->base_dir();

        unless ( $iter ) {

            $rule = Path::Iterator::Rule->new();
            $rule->min_depth( 12 );
            $rule->max_depth( 12 );
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

Catmandu::IdPath::UUID - A uuid based path translator

=head1 SYNOPSIS

    use Catmandu::IdPath::UUID;

    my $p = Catmandu::IdPath::UUID->new(
        base_dir => "/data"
    );

    #get path for record: "/data/9A5/81C/80-/118/9-1/1E8/-AB/6D-/46B/C15/3F8/9DB"
    my $path = $p->to_path("9A581C80-1189-11E8-AB6D-46BC153F89DB");

    #translate $path back to "9A581C80-1189-11E8-AB6D-46BC153F89DB"
    my $id = $p->from_path( $path );

    #Catmandu::IdPath::Number is a Catmandu::Iterable
    #Returns list of records: [{ _id => 1234, _path => "/data/000/001/234" }]
    my $id_paths = $p->to_array();

=head1 METHODS

=head2 new( base_dir => $path )

Create a new Catmandu::IdPath::UUID with the following configuration
parameters:

=over

=item base_dir

The base directory where the files are stored. Required

=back

=head1 INHERITED METHODS

This Catmandu::IdPath::Number implements:

=over 3

=item L<Catmandu::IdPath>

=back

=head1 SEE ALSO

L<Catmandu::IdPath>

=cut
