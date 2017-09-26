package Catmandu::Serializer::json;

use Catmandu::Sane;

our $VERSION = '1.0606';

use Cpanel::JSON::XS ();
use Moo;
use namespace::clean;

sub serialize {
    Cpanel::JSON::XS::encode_json($_[1]);
}

sub deserialize {
    Cpanel::JSON::XS::decode_json($_[1]);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Serializer - A (de)serializer from and to json

=head1 SYNOPSIS

    package MyPackage;

    use Moo;

    with 'Catmandu::Serializer';
    
    # You have now  serialize and deserialize methods available

    package main;

    my $obj = MyPackage->new;
    my $obj = MyPackage->new(serializer => 'json');

    $obj->serialize( { foo => 'bar' } );  # JSON 
    $obj->deserialize( "{'foo':'bar'}" );  # Perl

=head1 SEE ALSO

L<Catmandu::Serializer>

=cut
