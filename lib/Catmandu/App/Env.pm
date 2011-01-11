package Catmandu::App::Env;
# VERSION
use Moose::Role;
use Catmandu::App::Request;

has env => (is => 'ro', isa => 'HashRef', required => 1);
has req => (is => 'ro', isa => 'Plack::Request', lazy => 1, builder => '_build_req');

sub _build_req {
    Catmandu::App::Request->new($_[0]->env);
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

