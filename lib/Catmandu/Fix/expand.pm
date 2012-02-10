package Catmandu::Fix::expand;

use Catmandu::Sane;
use Moo;
use CGI::Expand qw(expand_hash);

sub fix {
    expand_hash($_[1]);
}

=head1 NAME

Catmandu::Fix::expand - convert a flat hash into nested data using the TT2 dot convention

=head1 SYNOPSIS

   # Collapse the data into a flat hash
   expand();

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
