package Catmandu::Exporter::Template;

use Catmandu::Sane;
use Catmandu::Util qw(is_invocant);
use Moo;
use Template;

with 'Catmandu::Exporter';

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

my $ADD_TT_EXT = sub { "$_[0].tt" if $_[0] !~ /\.tt$/ };

has xml             => (is => 'ro');
has template_before => (is => 'ro', coerce => $ADD_TT_EXT);
has template        => (is => 'ro', coerce => $ADD_TT_EXT, required => 1);
has template_after  => (is => 'ro', coerce => $ADD_TT_EXT);

$Template::Stash::PRIVATE = 0;

sub tt {
    state $tt = do {
        my $args = {
            ENCODING => 'utf8',
            ABSOLUTE => 1,
            ANYCASE  => 0,
        };

        if (is_invocant('Dancer')) {
            $args->{INCLUDE_PATH} = Dancer::setting('views');
            $args->{VARIABLES} = {
                settings => Dancer::Config->settings,
            };
        }

        Template->new($args);
    };
}

sub add {
    my ($self, $data) = @_;
    if ($self->count == 0) {
        $self->fh->print($XML_DECLARATION) if $self->xml;
        $self->tt->process($self->template_before, {}, $self->fh) if $self->template_before;
    }
    $self->tt->process($self->template, $data, $self->fh);
}

sub commit {
    my ($self) = @_;
    $self->tt->process($self->template_after, {}, $self->fh) if $self->template_after;
}

1;
