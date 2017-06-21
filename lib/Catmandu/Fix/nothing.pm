package Catmandu::Fix::nothing;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer, $label) = @_;
    "last ${label};";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::nothing - does nothing (for testing)

=head1 SYNOPSIS

   nothing()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
