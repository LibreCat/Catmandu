package Catmandu::Serializer::json;

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
