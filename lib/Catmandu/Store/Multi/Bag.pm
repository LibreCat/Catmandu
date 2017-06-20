package Catmandu::Store::Multi::Bag;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;

extends 'Catmandu::Store::Multi::Base';

with 'Catmandu::Bag';

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi::Bag - Bag implementation for the Multi store

=cut
