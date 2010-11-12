package Catmandu::App::Role;

use 5.010;
use Moose::Role;
use Catmandu;
use Catmandu::App::Request;
use Router::Simple;

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
    builder => '_build_response',
    handles => [qw(
        redirect
    )],
);

has params => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1, 
    default => sub { +{} },
);

sub _build_response {
    $_[0]->request->new_response(200, ['Content-Type' => "text/html"]);
}

sub req { $_[0]->request }
sub res { $_[0]->response }

sub session {
    $_[0]->request->env->{'psgix.session'};
}

sub param {
    my $self = shift;
    my $params = $self->params;
    return $params          if @_ == 0;
    return $params->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $params->{$key} = $val;
    }
    $params;
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

sub stash {
    my $stash = Catmandu->stash->{shift->app} //= {};
    return $stash          if @_ == 0;
    return $stash->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $stash->{$key} = $val;
    }
    $stash;
}

sub router {
    shift->app->stash->{_router} //= Router::Simple->new;
}

sub on_any {
    my $self = shift;

    if (@_ == 3) {
        my ($methods, $pattern, $sub) = @_;
        $self->router->connect($pattern, { _run => $sub }, { method => [ map { uc $_ } @$methods ] });
    } else {
        my ($pattern, $sub) = @_;
        $self->router->connect($pattern, { _run => $sub });
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
    $sub //= $self->param('_run');
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
    sub {
        my $env = $_[0];
        my $match = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];
        $app->new(request => Catmandu::App::Request->new($env), params => $match)
            ->run($match->{_run})
            ->response
            ->finalize;
    }
}

no Moose::Role;
__PACKAGE__;

