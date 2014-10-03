package Catmandu::Fixable;

=head1 NAME

Catmandu::Fixable - a Catmandu role to apply fixes

=head1 DESCRIPTION

This role provides a C<fix> attribute to apply fixes (instances of
L<Catmandu::Fix>) to items processed by L<Catmandu::Importer>,
L<Catmandu::Exporter>, and L<Catmandu::Bag>.
 
=cut

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_instance);
use Catmandu;
use Moo::Role;

has _fixer => (
    is => 'ro',
    init_arg => 'fix',
    coerce => sub {
        is_instance($_[0]) ? $_[0] : Catmandu->fixer($_[0]);
    },
);

1;
