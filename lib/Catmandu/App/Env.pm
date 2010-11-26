package Catmandu::App::Env;

use Moose::Role;
use Catmandu::App::Request;

has env => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has request => (
    is => 'ro',
    isa => 'Catmandu::App::Request',
    lazy => 1,
    builder => '_build_request',
);

sub _build_request {
    Catmandu::App::Request->new($_[0]->env);
}

sub req {
    $_[0]->request;
}

sub session {
    $_[0]->env->{'psgix.session'};
}

sub clear_session {
    my $self = shift;
    my $session = $self->session;
    my @keys = keys %$session;
    delete $session->{$_} for @keys;
    $session;
}

no Moose::Role;
__PACKAGE__;

