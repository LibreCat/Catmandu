package Catmandu::App::Env;
# VERSION
use Moose::Role;
use MooseX::Aliases;
use Plack::Request;

has env => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has request => (
    is => 'ro',
    isa => 'Plack::Request',
    alias => 'req',
    lazy => 1,
    builder => 'new_request',
);

sub new_request {
    Plack::Request->new($_[0]->env);
}

sub session {
    $_[0]->env->{'psgix.session'};
}

sub session_options {
    $_[0]->env->{'psgix.session.options'};
}

sub clear_session {
    if (my $ref = $_[0]->session) {
        delete $ref->{$_} for keys %$ref;
        $ref;
    }
}

no MooseX::Aliases;
no Moose::Role;

1;

