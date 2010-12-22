package Catmandu::App::Role::Object;

use namespace::autoclean;
use 5.010;
use Moose::Role;
use Catmandu;
use Catmandu::Util qw(load_class);
use Catmandu::App::Request;
use Catmandu::App::Router;
use Plack::Util;
use Plack::Middleware::Conditional;
use URI;
use List::Util qw(max);

with 'Catmandu::App::Env';

has response => (
    is => 'ro',
    isa => 'Catmandu::App::Response',
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

sub res {
    $_[0]->response
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
    push @$body, @_;
    $self->response->body($body);
}

sub print_template {
    my ($self, $tmpl, $vars) = @_;
    $vars ||= {};
    $vars->{app} = $self;
    Catmandu->print_template($tmpl, $vars, $self);
}

sub stash {
    my $class = ref $_[0] ? ref shift : shift;
    my $stash = Catmandu->stash->{$class} ||= {};
    return $stash          if @_ == 0;
    return $stash->{$_[0]} if @_ == 1;
    my %pairs = @_;
    while (my ($key, $val) = each %pairs) {
        $stash->{$key} = $val;
    }
    $stash;
}

sub run {
    my ($self, $sub) = @_;
    if (ref $sub eq 'CODE') {
        $sub->($self);
    } else {
        $self->$sub();
    }
    $self;
}

sub _middlewares {
    $_[0]->stash->{_middlewares} ||= [];
}

sub router {
    $_[0]->stash->{router} ||= Catmandu::App::Router->new;
}

sub add_middleware {
    my ($self, $sub, @args) = @_;
    if (ref $sub ne 'CODE') {
        my $pkg = load_class($sub, 'Plack::Middleware');
        $sub = sub { $pkg->wrap($_[0], @args) };
    }
    push @{$self->_middlewares}, $sub;
    1;
}

sub add_middleware_if {
    my ($self, $cond, $sub, @args) = @_;
    if (ref $sub ne 'CODE') {
        my $pkg = load_class($sub, 'Plack::Middleware');
        $sub = sub { $pkg->wrap($_[0], @args) };
    }
    push @{$self->_middlewares}, sub {
        Plack::Middleware::Conditional->wrap($_[0], condition => $cond, builder => $sub);
    };
    1;
}

sub add_route {
    my $opts = ref $_[-1] eq 'HASH' ? pop @_ : {};
    if (@_ == 4) {
        my ($self, $route, $name, $sub) = @_;
        $self->meta->add_method($name, $sub);
        $self->router->route(%$opts, app => ref $self ? ref $self : $self, sub => $name, path => $route);
    } else {
        my ($self, $route, $sub) = @_;
        $self->router->route(%$opts, app => ref $self ? ref $self : $self, sub => $sub, path => $route);
    }
    1;
}

sub add_mount {
    my ($self, $path, $app) = @_;
    load_class($app);
    $self->router->steal_routes($path, $app->router);
    1;
}

sub to_app {
    my $self = shift;
    my $router = $self->router;

    my $sub = sub {
        my $env = $_[0];
        my ($match, $route) = $router->match($env);
        $match or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];
        $route->app->new(env => $env, params => $match)
             ->run($route->sub)
             ->response->finalize;
    };

    $sub = $_->($sub) for reverse @{$self->_middlewares};

    $sub;
}

sub inspect_routes {
    my $self = shift;
    $self->router->stringify;
}

sub path_for {
    my $self = shift;
    $self->router->path_for(@_);
}

sub uri_for {
    my $self = shift;
    my $path = $self->router->path_for(@_) // return;
    my $base = $self->base_uri;

    $base =~ s!/$!!;
    $path =~ s!^/!!;
    "$base/$path";
}

sub base_path {
    $_[0]->env->{SCRIPT_NAME} || '/';
}

sub base_uri {
    my $env = $_[0]->env;

    my $uri = URI->new;
    $uri->scheme($env->{'psgi.url_scheme'} // $env->{'PSGI.URL_SCHEME'});
    $uri->authority($env->{HTTP_HOST} // "$env->{SERVER_NAME}:$env->{SERVER_PORT}");
    $uri->path($env->{SCRIPT_NAME} || '/');

    $uri->canonical;
}

1;

