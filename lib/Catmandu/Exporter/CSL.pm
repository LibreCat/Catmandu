package Catmandu::Exporter::CSL;

use Catmandu::Sane;
use Moo;
use HTTP::Tiny;
use JSON ();

with 'Catmandu::Exporter';
with 'Catmandu::Buffer';

has url => (is => 'ro', builder => '_build_url');
has http_client => (is => 'ro', lazy => 1, builder => '_build_http_client');
has style  => (is => 'ro');
has locale => (is => 'ro');
has format => (is => 'ro');

sub _build_url { 'http://localhost:8080' }

sub _build_http_client {
    HTTP::Tiny->new(default_headers => {'Accept' => 'application/json'});
}

sub BUILD {
    my ($self) = @_;
    my $query = {};
    for (qw(style locale format)) {
        $query->{$_} = $self->$_ if $self->$_;
    }
    if (keys %$query) {
        my $qs = $self->http_client->www_form_urlencode($query);
        $self->{url} .= "?$qs";
    }
}

sub add {
    my ($self, $data) = @_;
    $self->buffer_add($data);
    if ($self->buffer_is_full) {
        $self->commit;
    }
}

sub commit {
    my ($self) = @_;
    return unless $self->buffer_used;
    my $items = $self->buffer;
    $self->clear_buffer;
    my $response = $self->http_client->post($self->url, {content => JSON::encode_json({items => $items})});
    my $cites = JSON::decode_json($response->{content})->{items};
    $self->fh->print(@$cites);
}

=head1 NAME

Catmandu::Exporter::CSL - a exporter

=head1 SYNOPSIS

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
