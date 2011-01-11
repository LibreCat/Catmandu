package Catmandu::App;
# ABSTRACT: web application
# VERSION
use namespace::autoclean;
use Moose;
use MooseX::Traits;
use Catmandu::App::Router;
use Catmandu::App::Web;

has router => (is => 'ro', lazy => 1, builder => '_build_router');
has stash  => (is => 'ro', lazy => 1, builder => '_build_stash');

sub _build_router {
    Catmandu::App::Router->new;
}

sub _build_stash {
    {};
}

sub handle {
    my ($app, $sub, $web) = @_;
    if (ref $sub) {
        return $sub->($app, $web);
    }
    $app->$sub($web);
}

sub psgi_handler {
    my $router = $_[0]->router;

    my $sub = sub {
        my $env = $_[0];

        my ($match, $route) = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];

        my $web = Catmandu::App::Web->new(env => $env, parameters => $match);
        $route->app->handle($route->sub, $web);
        $web->res->finalize;
    };

    $sub;
}

__PACKAGE__->meta->make_immutable;

1;

