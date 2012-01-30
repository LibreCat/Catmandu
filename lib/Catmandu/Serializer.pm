package Catmandu::Serializer;

use Catmandu::Sane;
use Moo::Role;
use Storable ();
use Data::MessagePack;
use JSON ();
use MIME::Base64 ();

sub default_serialization_format { 'json' }

has serialization_format => (is => 'ro');
has serializer           => (is => 'ro', lazy => 1, builder => '_build_serializer');
has deserializer         => (is => 'ro', lazy => 1, builder => '_build_deserializer');

sub _build_serializer {
    my $self = $_[0];
    my $fmt  = $self->serialization_format || $self->default_serialization_format;
    return sub { MIME::Base64::encode(Storable::nfreeze($_[0])) } if $fmt eq 'storable';
    return sub { MIME::Base64::encode($self->_messagepack->pack($_[0])) } if $fmt eq 'messagepack';
    return sub { JSON::encode_json($_[0]) } if $fmt eq 'json';
    confess "unknown serialization format";
}

sub _build_deserializer {
    my $self = $_[0];
    my $fmt  = $self->serialization_format || $self->default_serialization_format;
    return sub { Storable::thaw(MIME::Base64::decode($_[0])) } if $fmt eq 'storable';
    return sub { $self->_messagepack->unpack(MIME::Base64::decode($_[0])) } if $fmt eq 'messagepack';
    return sub { JSON::decode_json($_[0]) } if $fmt eq 'json';
    confess "unknown serialization format";
}

sub _messagepack { state $messagepack = Data::MessagePack->new->utf8 }

sub serialize {
    $_[0]->serializer->($_[1]);
}

sub deserialize {
    $_[0]->deserializer->($_[1]);
}

1;
