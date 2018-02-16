package Catmandu::Path;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo::Role;
use Catmandu::Util qw(:check :is);
use Cwd;
use namespace::clean;

with "Catmandu::Iterable";

has base_dir => (
    is => "ro",
    isa => sub { check_string( $_[0] ); },
    required => 1,
    coerce => sub { Cwd::abs_path( $_[0] ); }
);

requires "to_path";
requires "from_path";

1;

__END__

=pod

=head1 NAME

Catmandu::Path - A base role for record based path translators

=head1 SYNOPSIS

    package MyPath;

    use Moo;
    use File::Spec;
    use File:Basename;

    with "Catmandu::Path";

    #required method: translate id to directory
    sub to_path {

        my ( $self, $id ) = @_;
        File::Spec->catdir( $self->base_dir(), $id );

    }

    #required method: translate path back to id
    sub from_path {

        my ( $self, $path ) = @_;

        my @split_path = File::Spec->splitdir( $path );
        @splice_path = splice(@split_path, scalar(File::Spec->splitdir( $self->base_dir )) );
        $splice_path[-1];

    }

    #return a generator that returns list of records, that maps _id and _path
    sub generator {

        my $self = $_[0];
        return sub {

            state $records;

            if ( !defined( $records ) ) {

                $records = [];

                opendir my $dh, $self->base_dir() or die($!);

                while( my $entry = readdir( $dh ) ){

                    if ( -d $entry ) {

                        push @$records, {
                            _id => $entry,
                            _path => File::Spec->catfile( $self->base_dir, $entry )
                        };

                    }
                }

                closedir $dh;

            }

            shift( @$records );
        };

    }

    package main;

    my $p = MyPath->new( base_dir => "/tmp" );

    Catmandu->store->bag->each(sub {
        say $p->to_path( $_[0] );
    });

=head1 METHODS

=head2 new( base_dir => $path )

Create a new Catmandu::Path::UUID with the following configuration
parameters:

=over

=item base_dir

The base directory where the files are stored. Required

=back

=head1 METHODS TO IMPLEMENT

Implementors must implement these methods

=over

=item to_path( $id )

* Accepts id as string

* Translates id to directory

* Returns directory as string

=item from_path( $path )

* Accepts directory as string

* Translates directory to id

* Returns id as string.

=back

=head1 INHERITED METHODS

This Catmandu::Path inherits:

=over 3

=item L<Catmandu::Iterable>

=back

=head1 SEE ALSO

L<Catmandu::Path::UUID> ,
L<Catmandu::Path::Number>

=cut
