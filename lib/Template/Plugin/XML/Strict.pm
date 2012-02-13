package Template::Plugin::XML::Strict;

use strict;
use warnings;
use parent qw(Template::Plugin::Filter);

my $FILTER_NAME = 'xml_strict';

sub init {
    my $self = $_[0];
    $self->install_filter($FILTER_NAME);
    $self;
}

sub filter {
    my $text = $_[1];
    for ($text) {
        s/&/&amp;/go;
        s/</&lt;/go;
        s/>/&gt;/go;
        s/"/&quot;/go;
        s/'/&apos;/go;
        # remove control characters
        s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;
    }
    $text;
}

1;
