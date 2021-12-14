package Catmandu::Fixable;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util qw(is_instance);
use Catmandu;
use Moo::Role;
use namespace::clean;

has _fixer => (
    is       => 'ro',
    init_arg => 'fix',
    coerce   => sub {Catmandu->fixer($_[0])},
);

1;

__END__

=pod

=head1 NAME

Catmandu::Fixable - a Catmandu role to apply fixes

=head1 DESCRIPTION

This role provides a C<fix> attribute to apply fixes to items processed by
L<Catmandu::Importer>, L<Catmandu::Exporter>, and L<Catmandu::Bag>.

=head1 CONFIGURATION

=head2 fix

An ARRAY of one or more fixes or file scripts to be applied to items.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
