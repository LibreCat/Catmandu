package Catmandu::Exporter::Template;

use Catmandu::Sane;
use Moo;
use Template;

with 'Catmandu::Exporter';

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

sub tt {
    state $tt = do {
        my $args = {
            ENCODING => 'utf8',
            ABSOLUTE => 1,
            ANYCASE  => 0,
        };

        if ($ENV{DANCER_APPDIR}) {
            require Dancer;
            $args->{INCLUDE_PATH} = Dancer::setting('views');
            $args->{VARIABLES} = {
                settings => Dancer::Config->settings,
            };
        }

        Template->new($args);
    };
}

has xml      => (is => 'ro');
has template => (is => 'ro', required => 1);

sub add {
    my ($self, $data) = @_;
    if ($self->count == 0 && $self->xml) {
        $self->fh->print($XML_DECLARATION);
    }
    $self->tt->process($self->template, $data, $self->fh);
    $data;
}

1;
