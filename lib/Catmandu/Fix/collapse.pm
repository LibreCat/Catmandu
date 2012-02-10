package Catmandu::Fix::collapse;

use Catmandu::Sane;
use Moo;
use CGI::Expand qw(collapse_hash);

sub fix {
    collapse_hash($_[1]);
}

=head1 NAME

Catmandu::Fix::collapse - convert nested data into a flat hash using the TT2 dot convention

=head1 SYNOPSIS

   # Collapse the data into a flat hash
   collapse();

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
