package Catmandu::Exporter::Template;

use Catmandu::Sane;
use Catmandu::Util qw(is_invocant);
use Moo;
use Template;

with 'Catmandu::Exporter';

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

has xml             => (is => 'ro');
has template_before => (is => 'ro');
has template        => (is => 'ro', required => 1);
has template_after  => (is => 'ro');
has tt              => (is => 'ro', lazy => 1, builder => '_build_tt');

$Template::Stash::PRIVATE = 0;

sub _build_tt {
    my $self = $_[0];
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
}

sub add {
    my ($self, $data) = @_;
    if ($self->count == 0) {
        $self->fh->print($XML_DECLARATION) if $self->xml;
        $self->tt->process($self->template_before, {}, $self->fh) if $self->template_before;
    }
    $self->tt->process($self->template, $data, $self->fh);
    $data;
}

sub commit {
    my ($self) = @_;
    $self->tt->process($self->template_after, {}, $self->fh) if $self->template_after;
}

1;
