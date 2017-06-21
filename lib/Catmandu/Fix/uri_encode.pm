package Catmandu::Fix::uri_encode;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use URI::Escape ();
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = URI::Escape::uri_escape_utf8(${var});";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Fix::uri_encode - percent encode a URI

=head1 SYNOPSIS

    # 'café' => '3%A9'
    uri_encode(place)

    # 'ὁ τῶν Πέρσων βασιλεύς' => '%E1%BD%81+%CF%84%E1%BF%B6%CE%BD+%CE%A0%CE%AD%CF%81%CF%83%CF%89%CE%BD+%CE%B2%CE%B1%CF%83%CE%B9%CE%BB%CE%B5%CF%8D%CF%82'
    uri_encode(title)

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::uri_decode>, L<URI::Escape>

=cut

