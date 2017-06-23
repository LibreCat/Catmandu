package Catmandu::Bag::IdGenerator::UUID;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Data::UUID;
use Moo;
use namespace::clean;

extends 'Catmandu::IdGenerator::UUID';

with 'Catmandu::Bag::IdGenerator';

1;

__END__

=pod

=head1 NAME

Catmandu::Bag::IdGenerator::UUID - Generator of UUID identifiers for bags

=cut
