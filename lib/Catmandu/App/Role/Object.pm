package Catmandu::App::Role::Object;

use 5.010;
use Moose::Role;
use Catmandu;
use Catmandu::App::Request;
use Router::Simple;
use Plack::Util;
use Plack::Middleware::Conditional;
use Plack::App::URLMap;
use List::Util qw(max);

has request => (
    is => 'ro',
    isa => 'Catmandu::App::Request',
    required => 1,
    handles => [qw(
        session
        env
    )],
);

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

sub req { $_[0]->request }
sub res { $_[0]->response }

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

sub _router {
    $_[0]->stash->{_router} ||= Router::Simple->new;
}

sub _mounts {
    $_[0]->stash->{_mounts} ||= {};
}

sub add_middleware {
    my ($self, $sub, @args) = @_;
    if (ref $sub ne 'CODE') {
        my $pkg = Plack::Util::load_class($sub, 'Plack::Middleware');
        $sub = sub { $pkg->wrap($_[0], @args) };
    }
    push @{$self->_middlewares}, $sub;
    1;
}

sub add_middleware_if {
    my ($self, $cond, $sub, @args) = @_;
    if (ref $sub ne 'CODE') {
        my $pkg = Plack::Util::load_class($sub, 'Plack::Middleware');
        $sub = sub { $pkg->wrap($_[0], @args) };
    }
    push @{$self->_middlewares}, sub {
        Plack::Middleware::Conditional->wrap($_[0], condition => $cond, builder => $sub);
    };
    1;
}

sub add_route {
    my ($self, $route, $sub, %opts) = @_;
    $self->_router->connect($route, { _run => $sub }, \%opts);
    1;
}

sub add_mount {
    my ($self, $path, $sub) = @_;
    $self->_mounts->{$path} = $sub;
    1;
}

sub to_app {
    my $self = shift;
    my $middlewares = $self->_middlewares;
    my $mounts = $self->_mounts;
    my $router = $self->_router;

    my $sub = sub {
        my $env = $_[0];
        my $match = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];
        $self->new(request => Catmandu::App::Request->new($env), params => $match)
            ->run($match->{_run})
            ->response->finalize;
    };

    $sub = $_->($sub) for reverse @$middlewares;

    if (keys %$mounts) {
        my $url_map = Plack::App::URLMap->new;
        $url_map->map('/', $sub);
        while (my ($path, $sub) = each %$mounts) {
            if (ref $sub ne 'CODE') {
                $sub = Plack::Util::load_class($sub)->to_app;
            }
            $url_map->map($path, $sub);
        }
        $sub = $url_map->to_app;
    }

    $sub;
}

sub inspect_routes {
    my $self = shift;
    my $mounts = $self->_mounts;
    my $router = $self->_router;

    my $text = "routes:\n" . join("", map(" $_\n", split(/\n/, $router->as_string)));

    if (keys %$mounts) {
        $text .= "mounts:\n";
        my $max = max map(length, keys %$mounts);
        while (my ($path, $sub) = each %$mounts) {
            $text .= sprintf " %-${max}s %s\n", $path, ref $sub || $sub;
        }
    }

    $text;
}

no Moose::Role;
__PACKAGE__;

