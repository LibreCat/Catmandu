package Catmandu::Serializer;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(require_package);
use Moo::Role;

has serialization_format => (
    is      => 'ro',
    builder => 'default_serialization_format',
);

has serializer => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_serializer',
    handles => [qw(serialize deserialize)]
);

sub default_serialization_format { 'json' }

sub _build_serializer {
    my ($self) = @_;
    my $pkg = require_package($self->serialization_format, 'Catmandu::Serializer');
    $pkg->new;
}

1;
