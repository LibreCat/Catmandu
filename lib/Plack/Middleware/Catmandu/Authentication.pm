package Plack::Middleware::Catmandu::Authentication;
use Catmandu::Sane;
use Catmandu::Util;
use Scalar::Util;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
    failure_app
    capture_401
    default_strategies
    default_scope
    strategies
    scopes
    into_session
    from_session
);

sub prepare_app {
    my $self = $_[0];
    $self->{default_strategies} ||= ['password'];
    $self->{default_scope} ||= 'user';
    $self->{strategies} ||= {};
    $self->{scopes} ||= {};
}

sub call {
    my ($self, $env) = @_;

    my $key = 'catmandu.authentication';

    if ($env->{$key} && $env->{$key}->app != $self) {
        return $self->app->($env); # authentication is already handled upstream
    }

    my $ref = Catmandu::Authentication->new(app => $self, env => $env);
    Scalar::Util::weaken($env->{$key} = $ref);

    my $response;

    try {
        $response = $self->app->($env);
        if ($self->capture_401 && $response->[0] == 401) {
            $response = $self->failure($env, $response);
        }
    } catch {
        my $e = $_;
        confess $e unless Catmandu::Util::is_instance($e => 'Catmandu::HTTP::Error');

        if ($e->error_code == 401) {
            $response = $self->failure($env, $e->psgi_response);
        } else {
            $e->throw;
        }
    };

    $response;
}

sub failure {
    [401, ['Content-Type' => 'text/plain'], ['fail']];
}

1;

