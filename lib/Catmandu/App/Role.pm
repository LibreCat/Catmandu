package Catmandu::App::Role;

use 5.010;
use Any::Moose '::Role';
use Catmandu;
use Catmandu::App::Request;
use Router::Simple;

with any_moose('X::Param');

has request => (
    is => 'ro',
    required => 1,
    handles => [qw(
        env
    )],
);

has response => (
    is => 'ro',
    lazy => 1,
    builder => '__build_response',
    handles => [qw(
        redirect
    )],
);

sub __build_response {
    $_[0]->request->new_response(200, ['Content-Type' => "text/html"]);
}

sub req { $_[0]->request }
sub res { $_[0]->response }

sub session {
    $_[0]->request->env->{'psgix.session'};
}

sub print {
    my $self = shift;
    my $body = $self->response->body // [];
    push(@$body, @_);
    $self->response->body($body);
}

sub print_template {
    Catmandu->print_template($_[1], $_[2] // {}, $_[0]);
}

sub app {
    ref $_[0] ? ref $_[0] : $_[0];
}

sub router {
    state $routers //= {}; $routers->{$_[0]->app} //= Router::Simple->new;
}

sub on_any {
    my $self = shift;

    if (@_ == 3) {
        my ($methods, $pattern, $sub) = @_;
        $self->router->connect($pattern, { run => $sub }, { method => [ map { uc $_ } @$methods ] });
    } else {
        my ($pattern, $sub) = @_;
        $self->router->connect($pattern, { run => $sub });
    }
}

sub on_get {
    my $self = shift; $self->on_any(['HEAD', 'GET'], @_);
}

sub on_put {
    my $self = shift; $self->on_any(['PUT'], @_);
}

sub on_post {
    my $self = shift; $self->on_any(['POST'], @_);
}

sub on_delete {
    my $self = shift; $self->on_any(['DELETE'], @_);
}

sub run {
    my ($self, $sub) = @_;
    $sub //= $self->param('run');
    if (ref $sub eq 'CODE') {
        $sub->($self);
    } else {
        $self->$sub();
    }
    $self;
}

sub as_psgi_app {
    my $app = $_[0]->app;
    my $router = $app->router;
    my $sub = sub {
        my $env = $_[0];
        my $match = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];
        $app->new({ request => Catmandu::App::Request->new($env),
                    params  => $match, })
            ->run($match->{run})
            ->response
            ->finalize;
    };

    $sub;
}

no Any::Moose '::Role';
__PACKAGE__;

