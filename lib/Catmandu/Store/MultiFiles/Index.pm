package Catmandu::Store::MultiFiles::Index;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Hits;
use Moo;
use Hash::Merge::Simple 'merge';
use namespace::clean;

with 'Catmandu::Store::Multi::Base', 'Catmandu::FileStore::Index';

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MultiFiles::Index - Bag implementation for the MultiFiles store

=cut
