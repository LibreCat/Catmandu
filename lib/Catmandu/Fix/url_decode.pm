package Catmandu::Fix::url_decode;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use URL::Encode;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = URL::Encode::url_decode_utf8( ${var} );";
}

1;

=pod

=head1 NAME

Catmandu::Fix::url_decode - url decode a string

=head1 SYNOPSIS

    # '3%A9' => 'café'
    url_decode(place)

    # '%E1%BD%81+%CF%84%E1%BF%B6%CE%BD+%CE%A0%CE%AD%CF%81%CF%83%CF%89%CE%BD+%CE%B2%CE%B1%CF%83%CE%B9%CE%BB%CE%B5%CF%8D%CF%82' => 'ὁ τῶν Πέρσων βασιλεύς'
    url_decode(title)

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::url_encode>, L<URL::Encode>

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut
