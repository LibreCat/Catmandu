package Plack::Middleware::Catmandu::Auth;

use 5.010;
use strict;
use warnings;
use base 'Plack::Middleware';
use Catmandu::Auth;
use Scalar::Util qw(blessed);
use Carp qw(confess);
use Try::Tiny;
use Plack::Util::Accessor qw(
    failure_app
    default_strategies
    default_scope
    strategies
    scopes
    into_session
    from_session
);

my $ENV_KEY = 'catmandu.auth';

my @DEFAULT_STRATEGIES = qw(simple);
my $DEFAULT_SCOPE = 'user';

sub prepare_app {
    my($self) = @_;
    $self->default_strategies || $self->default_strategies([@DEFAULT_STRATEGIES]);
    $self->default_scope || $self->default_scope($DEFAULT_SCOPE);
    $self->strategies || $self->strategies({});
    $self->scopes || $self->scopes({});
}

sub call {
    my($self, $env) = @_;

    if ($env->{$ENV_KEY} and $env->{$ENV_KEY} ne $self) {
        return $self->app->($env);
    }

    $env->{$ENV_KEY} = Catmandu::Auth->new(env => $env, app => $self);

    my $res = try {
        $self->app->($env);
    } catch {
        if (blessed $_ && $_->isa('Catmandu::HTTPErr') && $_->code == 401) {
            $_;
        } else {
            confess $_;
        }
    };

    if (ref $res eq 'ARRAY') {
        if ($res->[0] == 401) {
            return $self->_authentication_failed($env);
        } else {
            return $res;
        }
    }
    $self->_authentication_failed($env);
}

sub _authentication_failed {
    my ($self, $env) = @_;

    my $auth = $env->{$ENV_KEY};

    given ($auth->result) {
        when ('custom') {
            return $auth->custom_response;
        }
        default {
            my $app = $self->failure_app or
                Carp::confess "Missing failure app";
            return $app->($env);
        }
    }
}

1;

