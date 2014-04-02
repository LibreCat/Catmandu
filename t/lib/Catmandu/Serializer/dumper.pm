package Catmandu::Serializer::dumper;

use Catmandu::Sane;
use Data::Dumper;
use Moo;

sub serialize {
    Dumper($_[1]);
}

sub deserialize {
    eval($_[1]);
}

1;
