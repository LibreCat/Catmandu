package Catmandu::Fix::url_encode;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use URL::Encode;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = URL::Encode::url_encode_utf8( ${var} );";
}

1;

=pod

=head1 NAME

Catmandu::Fix::url_encode - url encode a string

=head1 SYNOPSIS

    # 'café' => '3%A9'
    url_encode(place)

    # 'ὁ τῶν Πέρσων βασιλεύς' => '%E1%BD%81+%CF%84%E1%BF%B6%CE%BD+%CE%A0%CE%AD%CF%81%CF%83%CF%89%CE%BD+%CE%B2%CE%B1%CF%83%CE%B9%CE%BB%CE%B5%CF%8D%CF%82'
    url_encode(title)

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::url_decode>, L<URL::Encode>

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut

