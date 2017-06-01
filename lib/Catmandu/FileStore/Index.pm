package Catmandu::FileStore::Index;

our $VERSION = '1.0507';

use Catmandu::Sane;
use Moo::Role;
use IO::String;
use utf8;
use Catmandu::Util qw(:check);
use namespace::clean;

with 'Catmandu::Bag';

1;

__END__

=pod

=head1 NAME

Catmandu::FileStore::Index - Flag a Bag as a FileStore Index

=cut
