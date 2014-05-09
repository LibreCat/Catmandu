package Catmandu::Fix::nothing;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer, $label) = @_;
    "last ${label};";
}

=head1 NAME

Catmandu::Fix::nothing - does nothing (for testing)

=head1 SYNOPSIS

   nothing()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
