package Catmandu::PathIndex;

use Catmandu::Sane;

our $VERSION = '1.08';

use Moo::Role;
use namespace::clean;

with "Catmandu::Iterable";

requires "get";
requires "add";
requires "delete";
requires "delete_all";

1;

__END__

=pod

=head1 NAME

Catmandu::PathIndex - A base role to store relation between id and path

=head1 SYNOPSIS

    package MyPath;

    use Moo;
    use File::Spec;
    use File:Basename;
    use Path::Tiny qw(path);

    with "Catmandu::PathIndex";

    # translate id to directory
    sub _to_path {
        my ( $self, $id ) = @_;
        File::Spec->catdir( $self->base_dir(), $id );
    }

    sub get {

        my ( $self, $id ) = @_;
        my $path = $self->_to_path( $id );

        is_string( $path ) && -d $path ? { _id => $id, _path => $path } : undef;

    }
    sub add {

        my ( $self, $id ) = @_;
        my $path = $self->_to_path( $id );

        path( $path )->mkpath unless -d $path;

        { _id => $id, _path => $path };

    }
    sub delete {

        my ( $self, $id ) = @_;
        my $path = $self->_to_path( $id );

        if ( is_string( $path ) && -d $path ) {

            path( $path )->remove_tree();

        }

    }
    sub delete_all {

        path( $_[0]->base_dir )->remove_tree({ keep_root => 1 });

    }

    # return a generator that returns list of records, that maps _id and _path
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

        my $r = $_[0];
        my $mapping = $p->get( $r->{_id} ) || $p->add( $r->{_id} );
        say $id . " => " . $mapping->{path};

    });

=head1 METHODS TO IMPLEMENT

Implementors must implement these methods

=over

=item add( $id ) : $mapping

* Accepts id as string

* Translates id to directory

* Creates directory if necessary

* Returns record containing _id and _path

This method should throw an error when it detects an invalid id.

It should either return the mapping or throw an error.

=item get( $id ) : $mapping

* Accepts id as string

* Translates id to directory

* Returns record containing _id and _path, but only if an existing path was found

This method should throw an error when it detects an invalid id.

Difference with method "add":

* no directory created

* no mapping returned if no existing directory could be found

=item delete ( $id )

* Accepts id as string

* Translates id to directory

* Removes directory if it exists

* Do other internal cleanup actions if any required

=item delete_all()

* Deletes files/directories in base_dir. Please keep the base_dir.

* Do other internal cleanup actions if any required

=back

=head1 INHERITED METHODS

This Catmandu::PathIndex inherits:

=over 3

=item L<Catmandu::Iterable>

=back

=head1 SEE ALSO

L<Catmandu::Store::File::Simple> ,
L<Catmandu::PathIndex::UUID> ,
L<Catmandu::PathIndex::Number>

=cut
