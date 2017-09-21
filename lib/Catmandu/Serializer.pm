package Catmandu::Serializer;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Catmandu::Util qw(require_package);
use Moo::Role;
use namespace::clean;

has serialization_format =>
    (is => 'ro', builder => 'default_serialization_format',);

has serializer => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_serializer',
    handles => [qw(serialize deserialize)]
);

sub default_serialization_format {'json'}

sub _build_serializer {
    my ($self) = @_;
    my $pkg = require_package($self->serialization_format,
        'Catmandu::Serializer');
    $pkg->new;
}

# Implementer needs to be create a serializer
# sub serialize {}

# Implementers needs to be create a deserializer
# sub deserialize {}

1;

__END__

=pod

=head1 NAME

Catmandu::Serializer - Base class for all Catmandu Serializers

=head1 SYNOPSIS

    package Catmandu::Serializer::Foo;

    use Moo;

    sub serialize {
        my ($self,$data) = @_;
        .. transform the data to a string and return it...
    }

    sub deserialize {
        my ($self,$string) = @_;
        ... transform the string into a perl hash ...
    }

    package MyPackage;

    use Moo;

    with 'Catmandu::Serializer';

    package main;

    my $pkg = MyPackage->new;

    my $string = $pkg->serialize({ foo => 'bar' });
    my $perl   = $pkg->deserialize($string);

    # Using Catmandu::Serializer::Foo 
    my $pkg = MyPackage->new( serialization_format => 'Foo' );

    my $string = $pkg->serialize({ foo => 'bar' });
    my $perl   = $pkg->deserialize($string);
	
=head1 DESCRIPTION

This is a convience class to send Perl hashes easily over the wire without having to
instantiate a L<Catmandu::Importer> and L<Catmandu::Exporter> which are more suited for
processing IO streams.

=head1 ATTRIBUTES

=head1 serialization_format

The name of the package that serializes data.

=head1 serializer

An instance of the package that serializes.

=head1 METHODS

=head2 serialize($perl)

Serialize a perl data structure into a string.

=head2 deserialize($bytes)

Deserialize bytes into a perl data structure.

=head1 SEE ALSO

L<Catmandu::Store::DBI>, 
L<Catmandu::Serializer::json>,
L<Catmandu::Serializer::storabe>,
L<Catmandu::Serializer::messagepack>

=cut
