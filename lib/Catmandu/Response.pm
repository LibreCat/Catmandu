package Catmandu::Response;
use Catmandu::Sane;
use parent qw(Plack::Response);
use Encode ();

sub print {
    my $self = shift;
    my $body = $self->body || [];
    push @$body, map Encode::encode_utf8($_), @_;
    $self->body($body);
}

1;
