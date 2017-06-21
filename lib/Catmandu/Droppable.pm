package Catmandu::Droppable;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo::Role;
use namespace::clean;

requires 'drop';

1;

__END__

=pod

=head1 NAME

Catmandu::Droppable - Optional role for droppable stores or bags

=head1 SYNOPSIS

    # delete a store
    $store->drop;
    # delete a single bag
    $store->bag('sessions')->drop;

=head1 METHODS

=head2 drop

Drop the store or bag.

=cut

