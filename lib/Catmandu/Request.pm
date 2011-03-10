package Catmandu::Request;
use Catmandu::Sane;
use Catmandu::Response;
use parent qw(Plack::Request);

sub new_response {
    Catmandu::Response->new(200, ['Content-Type' => 'text/html']);
}

1;
