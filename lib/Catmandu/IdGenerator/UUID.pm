package Catmandu::IdGenerator::UUID;

use Catmandu::Sane;
use Data::UUID;
use Moo;
use namespace::clean;

with 'Catmandu::IdGenerator';

has _uuid => (is => 'lazy', builder => '_build_uuid');

sub _build_uuid { Data::UUID->new }

sub generate {
    $_[0]->_uuid->create_str;
}

1;
