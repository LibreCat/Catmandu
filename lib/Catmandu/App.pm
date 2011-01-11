package Catmandu::App::Handler;

use Moose;
use HTTP::Status;

has req => (
    is => 'ro',
);

has res => (
    is => 'ro',
    default => sub { $_[0]->req->new_response(200) },
);

has [qw(head get put post delete)] => (
    is => 'ro',
    isa => 'CodeRef',
    lazy => 1,
    default => sub {
        $_[0]->res($_[0]->req->new_response(405, ['Content-Type' => 'text/plain'], [HTTP::Status::status_message(405)]));
    },
)

package Catmandu::App;
# ABSTRACT: web application class
# VERSION
use namespace::autoclean;
use Moose;
use MooseX::Traits;
use Catmandu::App::Router;

has router => (is => 'ro', lazy => 1, builder => '_build_router');
has stash  => (is => 'ro', lazy => 1, builder => '_build_stash');

sub _build_router {
    Catmandu::App::Router->new;
}

sub _build_stash {
    {};
}

sub run {
    my $self = $_[0];

    sub {
        my $env = $_[0];
        my $ = Catmandu::App::Request->new(params => $match, env => $env);
        
    }
}

__PACKAGE__->meta->make_immutable;

1;

