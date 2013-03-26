package Catmandu::Serializer;

use namespace::clean;
use Catmandu::Sane;
use Storable ();
use Data::MessagePack;
use JSON ();
use MIME::Base64 ();
use Moo::Role;

sub default_serialization_format { 'json' }

my $messagepack = Data::MessagePack->new->utf8;
my $formats = {
    storable => {
        serializer   => sub { MIME::Base64::encode(Storable::nfreeze($_[0])) },
        deserializer => sub { Storable::thaw(MIME::Base64::decode($_[0])) },
    },
    messagepack => {
        serializer   => sub { MIME::Base64::encode($messagepack->pack($_[0])) },
        deserializer => sub { $messagepack->unpack(MIME::Base64::decode($_[0])) },
    },
    json => {
        serializer   => sub { JSON::encode_json($_[0]) },
        deserializer => sub { JSON::decode_json($_[0]) },
    },
};

has serialization_format => (is => 'ro', default => sub { '' });
has serializer           => (is => 'ro', lazy => 1, builder => '_build_serializer');
has deserializer         => (is => 'ro', lazy => 1, builder => '_build_deserializer');

sub _build_serializer {
    my $self = $_[0];
    my $format = $formats->{$self->serialization_format || $self->default_serialization_format}
        or Catmandu::BadArg->throw("unknown serialization format");
    $format->{serializer};
}

sub _build_deserializer {
    my $self = $_[0];
    my $format = $formats->{$self->serialization_format || $self->default_serialization_format}
        or Catmandu::BadArg->throw("unknown serialization format");
    $format->{deserializer};
}

sub serialize {
    $_[0]->serializer->($_[1]);
}

sub deserialize {
    $_[0]->deserializer->($_[1]);
}

1;
