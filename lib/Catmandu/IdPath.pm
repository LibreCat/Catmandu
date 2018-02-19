package Catmandu::IdPath;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo::Role;
use namespace::clean;

with "Catmandu::Iterable";

requires "to_path";
requires "from_path";

1;

__END__

=pod

=head1 NAME

Catmandu::IdPath - A base role to calculate directory to FileBags

=head1 SYNOPSIS

    package MyPath;

    use Moo;
    use File::Spec;
    use File:Basename;

    with "Catmandu::IdPath";

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

=head1 METHODS TO IMPLEMENT

Implementors must implement these methods

=over

=item to_path( $id )

* Accepts id as string

* Translates id to directory

* Returns directory as string

This method should throw an error when it detects an invalid id.

Only the implementor can decide what should be a valid id.

This method should not create the path. That is the responsibility of the user.

=item from_path( $path )

* Accepts directory as string

* Translates directory to id

* Returns id as string.

This method should throw an error when it detects an invalid id.

Only the implementor can decide what should be a valid id.

=back

=head1 INHERITED METHODS

This Catmandu::IdPath inherits:

=over 3

=item L<Catmandu::Iterable>

=back

=head1 SEE ALSO

L<Catmandu::IdPath::UUID> ,
L<Catmandu::IdPath::Number>

=cut
