package Catmandu::Bag::IdGenerator::Mock;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Data::UUID;
use Moo;
use namespace::clean;

extends 'Catmandu::IdGenerator::Mock';

with 'Catmandu::Bag::IdGenerator';

1;

__END__

=pod

=head1 NAME

Catmandu::Bag::IdGenerator::Mock - Generator of increasing identifiers for bags

=cut
