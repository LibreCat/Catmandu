package Catmandu::Types;

use warnings;
use strict;
use MooseX::Types::Moose qw(Str Object);
use JSON::Path;
use namespace::clean;
use MooseX::Types -declare => [qw(JSONPath)];

subtype JSONPath, as Object;

coerce JSONPath,
    from Str,
        via { JSON::Path->new($_) };

1;

