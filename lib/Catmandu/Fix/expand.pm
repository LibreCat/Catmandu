package Catmandu::Fix::expand;

use Catmandu::Sane;
use Moo;
use CGI::Expand ();

sub fix {
    CGI::Expand->expand_hash($_[1]);
}

=head1 NAME

Catmandu::Fix::expand - convert a flat hash into nested data using the TT2 dot convention

=head1 SYNOPSIS

   # collapse the data into a flat hash
   collapse()
   # expand again to the nested original
   expand()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
