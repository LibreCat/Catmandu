package Catmandu::Fix::uri_decode;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Encode qw(decode_utf8);
use URI::Escape qw(uri_unescape);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)
        ->updater(if_string => sub {decode_utf8(uri_unescape($_[0]))});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Fix::uri_decode - percent decode a URI

=head1 SYNOPSIS

    # '3%A9' => 'café'
    uri_decode(place)

    # '%E1%BD%81+%CF%84%E1%BF%B6%CE%BD+%CE%A0%CE%AD%CF%81%CF%83%CF%89%CE%BD+%CE%B2%CE%B1%CF%83%CE%B9%CE%BB%CE%B5%CF%8D%CF%82' => 'ὁ τῶν Πέρσων βασιλεύς'
    uri_decode(title)

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::uri_encode>, L<URI::Escape>

=cut
