package Catmandu::App;
# VERSION
use Moose;
use Catmandu::Util qw(load_class);
use Catmandu::App::Router;
use Catmandu::App::Web;
use Plack::Middleware::Conditional;

with qw(
    MooseX::SingletonMethod::Role
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

sub route {
    my ($self, $pattern, %opts) = @_;
    if (my $name = delete $opts{as}) {
        unless ($self->meta->has_method($name)) {
            $self->add_singleton_method($name => $opts{to});
        }
        $opts{to} = $name;
    }
    $self->router->route(%opts, app => $self, path => $pattern);
    $self;
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
    push @{$self->middlewares}, [ $mw, $cond, %opts ];
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
    my $router = $self->router;

    my $sub = sub {
        my $env = $_[0];

        my ($match, $route) = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];

        my $app = $route->app;
        my $web = Catmandu::App::Web->new(app => $app, env => $env, parameters => $match);
        $app->run($route->to, $web);
        $web->res->finalize;
    };

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

__PACKAGE__->meta->make_immutable;

no Moose;
no Catmandu::Util;

1;

