package Catmandu::App::Env;
# VERSION
use Moose::Role;
use Plack::Request;

has env => (is => 'ro', isa => 'HashRef', required => 1);
has req => (is => 'ro', isa => 'Plack::Request', lazy => 1, builder => 'new_request');

sub new_request {
    Plack::Request->new($_[0]->env);
}

sub request {
    $_[0]->req;
}

sub session {
    $_[0]->env->{'psgix.session'};
}

sub clear_session {
    if (my $ref = $_[0]->session) {
        delete $ref->{$_} for keys %$ref;
        $ref;
    }
}

no Moose::Role;

1;

