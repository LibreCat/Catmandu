package Catmandu::App;
# VERSION
use Moose;
use Catmandu::Util qw(load_class);
use Catmandu::App::Router;
use Catmandu::App::Web;
use Plack::Middleware::Conditional;

with qw(
    MooseX::SingletonMethod
    MooseX::Traits
);

has middlewares => (is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_middlewares');
has router      => (is => 'ro',                    lazy => 1, builder => '_build_router');
has stash       => (is => 'ro', isa => 'HashRef',  lazy => 1, builder => '_build_stash');

sub _build_router {
    Catmandu::App::Router->new;
}

sub _build_middlewares {
    [];
}

sub _build_stash {
    {};
}

sub add_route {
    my ($self, $route, %opts) = @_;
    if (my $name = delete $opts{name}) {
        unless ($self->meta->has_method($name)) {
            $self->add_singleton_method($name => $opts{sub});
        }
        $opts{sub} = $name;
    }
    $self->router->route(%opts);
    $self;
}

sub add_mount {
    my ($self, $path, $app) = @_;
    load_class($app);
    $self->router->steal_routes($path, $app->router);
    $self;
}

sub add_middleware {
    my ($self, $mw, %opts) = @_;
    push @{$self->middlewares}, [$mw, %opts];
    $self;
}

sub run {
    my ($self, $sub, $web) = @_;
    if (ref $sub) {
        return $sub->($self, $web);
    }
    $self->$sub($web);
}

sub psgi_app {
    my $self = shift;
    my $middlewares = $self->middlewares;
    my $router = $self->router;

    my $sub = sub {
        my $env = $_[0];

        my ($match, $route) = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];

        my $app = $route->app;
        my $web = Catmandu::App::Web->new(app => $app, env => $env, parameters => $match);
        $app->run($route->sub, $web);
        $web->res->finalize;
    };

    foreach (@$middlewares) {
        my ($mw, %opts) = @$_;
        my $cond = delete $opts{if};
        if (ref $mw eq "CODE") {
            
        } else {
            
        }

        unless (ref $mw eq 'CODE') {
            my $mw = load_class($mw, 'Plack::Middleware');
        }
    }

    $sub;
}

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Util;

1;

