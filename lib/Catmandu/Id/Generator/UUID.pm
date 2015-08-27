package Catmandu::Id::Generator::UUID;
use Catmandu::Sane;
use Data::UUID;
use Moo;
use namespace::clean;

with 'Catmandu::Id::Generator';

has _uuid => (
    is => 'ro',
    lazy => 1,
    default => sub { Data::UUID->new; }
);

sub generate {
    $_[0]->_uuid()->create_str();
}

1;
