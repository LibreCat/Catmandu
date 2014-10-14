package Catmandu::Serializer::json;

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

use Catmandu::Sane;
use JSON ();
use Moo;

sub serialize {
    JSON::encode_json($_[1]);
}

sub deserialize {
    JSON::decode_json($_[1]);
}

1;
