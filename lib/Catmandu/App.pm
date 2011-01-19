package Catmandu::App;
# VERSION
use Moose;

BEGIN {
    extends qw(MooseX::MethodAttributes::Inheritable);
}

use MooseX::MethodAttributes;
use MooseX::Aliases;
use Catmandu::App::Router;
use Catmandu::App::Web;
use Catmandu::Util qw(load_class unquote trim);
use Plack::Middleware::Conditional;

with qw(
    MooseX::SingletonMethod::Role
    MooseX::Traits
);

has middlewares => (is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_middlewares');
has router      => (is => 'ro',                    lazy => 1, builder => '_build_router');
has stash       => (is => 'ro', isa => 'HashRef',  lazy => 1, builder => '_build_stash');

sub _build_middlewares {
    [];
}

sub _build_router {
    Catmandu::App::Router->new;
}

sub _build_stash {
    {};
}

sub _parse_method_attributes {
    my $self = shift;

    for my $method ($self->meta->get_nearest_methods_with_attributes) {
        for my $attr (@{$method->attributes}) {
            if (my $http_method = $attr =~ /^GET|PUT|POST|DELETE$/) {
                $self->route('/' . $method->name, as => $method->name, methods => [$http_method]);
            }
            elsif ($attr =~ /^route|R$/) {
                $self->route('/' . $method->name, as => $method->name);
            }
            elsif (my ($http_method, $pattern) = $attr =~ /^(GET|PUT|POST|DELETE)\((.+)\)$/) {
                $self->route(trim(unquote($pattern)), as => $method->name, methods => [$http_method]);
            }
            elsif (my ($args) = $attr =~ /^(?:route|R)\((.+)\)$/) {
                my @http_methods = map { trim unquote $_ } split /,/, $args;
                my $pattern = $http_methods[0] =~ /^GET|PUT|POST|DELETE$/ ? $method->name : shift @http_methods;
                if (@http_methods) {
                    $self->route($pattern, as => $method->name, methods => \@http_methods);
                } else {
                    $self->route($pattern, as => $method->name);
                }
            }
        }
    }
}

sub BUILD {
    my ($self, $args) = @_;

    $self->_parse_method_attributes;

    if (ref $args->{routes} eq 'ARRAY') {
        $self->route(@$_) for @{$args->{routes}};
    }

    $self->initialize;
}

sub initialize {
    # empty hook
}

sub set {
    my ($self, $key, $value) = @_;
    $self->stash->{$key} = $value;
    $self;
}

sub route {
    my ($self, $pattern, %opts) = @_;
    $opts{sub} ||= delete($opts{run}) ||
                   delete($opts{to});

    $opts{app} = $self;

    if ($opts{methods}) {
        $opts{methods} = [map uc, @{$opts{methods}}];
    }

    if (my $name = delete $opts{as}) {
        unless ($self->meta->has_method($name)) {
            $self->add_singleton_method($name => $opts{sub});
        }
        $opts{sub} = $name;
    }

    $self->router->route($pattern, %opts);
    $self;
}

alias R => 'route';

sub GET {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['GET', 'HEAD']);
    $self;
}

sub PUT {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['PUT']);
    $self;
}

sub POST {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['POST']);
    $self;
}

sub DELETE {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['DELETE']);
    $self;
}

sub method_not_allowed {
    $_[1]->custom_response([ 405, ['Content-Type' => "text/plain"], ["Method Not Allowed"] ]);
}

sub not_found {
    $_[1]->custom_response([ 404, ['Content-Type' => "text/plain"], ["Not Found"] ]);
}

sub mount {
    my ($self, $path, $app) = @_;
    load_class($app);
    $self->router->steal_routes($path, $app->router);
    $self;
}

sub middleware {
    my ($self, $mw, %opts) = @_;
    my $cond = delete $opts{if};
    push @{$self->middlewares}, [$mw, $cond, %opts];
    $self;
}

sub wrap_middleware {
    my ($self, $sub) = @_;

    foreach (reverse @{$self->middlewares}) {
        my ($mw, $cond, %opts) = @$_;

        if (ref $mw eq "CODE") {
            $sub = $cond ?
                Plack::Middleware::Conditional->wrap($sub, condition => $cond, builder => $mw) :
                $mw->($sub);
        } else {
            load_class($mw, 'Plack::Middleware');
            $sub = $cond ?
                Plack::Middleware::Conditional->wrap($sub, condition => $cond, builder => sub { $mw->wrap($_[0], %opts) }) :
                $mw->wrap($sub, %opts);
        }
    }

    $sub;
}

sub run {
    my ($self, $sub, $web) = @_;
    if (ref $sub) {
        $sub->($self, $web);
    } else {
        $self->$sub($web);
    }
    $web;
}

sub psgi_app {
    my $self   = ref $_[0] ? $_[0] : $_[0]->new;
    my $router = $self->router;

    $self->wrap_middleware(sub {
        my $env = $_[0];
        my $app;
        my $sub;
        my $web;

        my ($match, $route, $code) = $router->match($env);

        if ($match) {
            $app = $route->app;
            $sub = $route->sub;
            $web = Catmandu::App::Web->new(app => $app, env => $env, parameters => $match);
        } else {
            $app = $self;
            $sub = $code == 405 ? 'method_not_allowed' : 'not_found';
            $web = Catmandu::App::Web->new(app => $app, env => $env);
        }

        $app->run($sub, $web);

        $web->has_custom_response ?
            $web->custom_response :
            $web->response->finalize;
    });
}

__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::Aliases;
no Catmandu::Util;

1;

