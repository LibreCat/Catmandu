package Catmandu::Store::Multi;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::Multi::Bag;
use Moo;

with 'Catmandu::Store';

has stores => (is => 'ro', default => sub { [] });

1;

=head1 NAME

Catmandu::Store::Multi - A store that adds your data to multiple stores

=cut
