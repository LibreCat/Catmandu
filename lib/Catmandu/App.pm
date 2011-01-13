package Catmandu::App;
# VERSION
use Moose;
use Catmandu::Util;
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

sub _build_middlewares {
    [];
}

sub _build_router {
    Catmandu::App::Router->new;
}

sub _build_stash {
    {};
}

sub route {
    my ($self, $path, %opts) = @_;
    $opts{sub} ||= delete($opts{run}) ||
                   delete($opts{to});

    $opts{path} = $path;
    $opts{app}  = $self;

    if (my $name = delete $opts{as}) {
        unless ($self->meta->has_method($name)) {
            $self->add_singleton_method($name => $opts{sub});
        }
        $opts{sub} = $name;
    }

    $self->router->route(%opts);
    $self;
}

sub set {
    my ($self, $key, $value) = @_;
    $self->stash->{$key} = $value;
    $self;
}

sub get {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['GET', 'HEAD']);
    $self;
}

sub put {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['PUT']);
    $self;
}

sub post {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['POST']);
    $self;
}

sub delete {
    my ($self, $pattern, %opts) = @_;
    $self->route($pattern, %opts, methods => ['DELETE']);
    $self;
}

sub mount {
    my ($self, $path, $app) = @_;
    Catmandu::Util::load_class($app);
    $self->router->steal_routes($path, $app->router);
    $self;
}

sub middleware {
    my ($self, $mw, %opts) = @_;
    my $cond = delete $opts{if};
    push @{$self->middlewares}, [$mw, $cond, %opts];
    $self;
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
    my $self = ref $_[0] ? $_[0] : $_[0]->new;
    my $middlewares = $self->middlewares;
    my $router = $self->router;

    my $sub = sub {
        my $env = $_[0];

        my ($match, $route) = $router->match($env)
            or return [ 404, ['Content-Type' => "text/plain"], ["Not Found"] ];

        my $app = $route->app;
        my $web = Catmandu::App::Web->new(
            app => $app,
            env => $env,
            parameters => $match,
        );

        $app->run($route->sub, $web);
        $web->res->finalize;
    };

    foreach my $args (reverse @$smiddlewares) {
        my ($mw, $cond, %opts) = @$args;

        if (ref $mw eq "CODE") {
            $sub = $cond ?
                Plack::Middleware::Conditional->wrap($sub, condition => $cond, builder => $mw) :
                $mw->($sub);
        } else {
            Catmandu::Util::load_class($mw, 'Plack::Middleware');
            $sub = $cond ?
                Plack::Middleware::Conditional->wrap($sub, condition => $cond, builder => sub { $mw->wrap($_[0], %opts) }) :
                $mw->wrap($sub, %opts);
        }
    }

    $sub;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

