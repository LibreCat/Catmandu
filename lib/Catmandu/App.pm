package Catmandu::App;
# VERSION
use 5.010;
use Moose;

BEGIN {
    extends qw(MooseX::MethodAttributes::Inheritable);
}

use MooseX::MethodAttributes;
use MooseX::Aliases;
use List::Util qw(max);
use Catmandu::Util qw(load_class unquote trim);
use Catmandu::App::Route;
use Plack::Middleware::Conditional;
use Plack::Request;
use Plack::Response;
use Encode ();
use Hash::Merge::Simple qw(merge);
use Hash::MultiValue;
use CGI::Expand;
use URI;

with qw(
    MooseX::SingletonMethod::Role
    MooseX::Traits
);

has middlewares => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [] },
);

has routes => (
    is => 'ro',
    isa => 'ArrayRef[Catmandu::App::Route]',
    default => sub { [] },
);

has stash => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub { {} },
);

has request => (
    is => 'rw',
    isa => 'Plack::Request',
    alias => 'req',
    handles => [qw(
        env
        session
        session_options
    )],
);

sub BUILD {
    my ($self, $args) = @_;

    $self->_parse_method_attributes;
}

sub _parse_method_attributes {
    my $self = shift;

    for my $method ($self->meta->get_nearest_methods_with_attributes) {
        for my $attr (@{$method->attributes}) {
            if (my ($http_method) = $attr =~ /^(GET|PUT|POST|DELETE)$/) {
                $self->route('/' . $method->name, as => $method->name, methods => [$http_method]);
                next;
            }
            if ($attr =~ /^(route|R)$/) {
                $self->route('/' . $method->name, as => $method->name);
                next;
            }
            if (my ($http_method, $pattern) = $attr =~ /^(GET|PUT|POST|DELETE)\((.+)\)$/) {
                $self->route(trim(unquote($pattern)), as => $method->name, methods => [$http_method]);
                next;
            }
            if (my ($args) = $attr =~ /^(?:route|R)\((.+)\)$/) {
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

sub set {
    my ($self, $key, $value) = @_;
    $self->stash->{$key} = $value;
    $self;
}

sub route {
    my ($self, $pattern, %opts) = @_;

    $opts{pattern} = $pattern;

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

    push @{$self->routes}, Catmandu::App::Route->new(%opts);

    $self;
}

alias R => 'route';

sub mount {
    my ($self, $pattern, $app, $defaults) = @_;

    confess "Pattern must start with a slash" if $pattern !~ /^\//;
    confess "Pattern cannot end with a slash" if $pattern =~ /\/$/;

    $app = load_class($app)->new unless ref $app;

    $defaults ||= {};

    push @{$self->routes}, map {
        Catmandu::App::Route->new(
            app => $_->app,
            sub => $_->sub,
            pattern => $pattern . $_->pattern,
            defaults => merge($_->defaults, $defaults),
            methods => $_->methods,
        );
    } @{$app->routes};

    $self;
}
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

sub match_route {
    my ($self, $env) = @_;

    my $code = 404;

    for my $route (@{$self->routes}) {
        my ($parameters, $c) = $route->match($env);
        if ($parameters) {
            return $route, $parameters, $c;
        } elsif ($code == 404 && $c != 404) {
            $code = $c;
        }
    }

    return undef, undef, $code;
}

sub inspect_routes {
    my $self = shift;

    my $routes = $self->routes;

    my $max_a = max(map { length ref $_->app } @$routes);
    my $max_m = max(map { length join(',', $_->method_list) } @$routes);
    my $max_s = max(map { $_->named ? length $_->sub : 7 } @$routes);

    join '', map {
        sprintf "%-${max_a}s %-${max_m}s %-${max_s}s %s\n",
            ref $_->app,
            join(',', $_->method_list),
            $_->named ? $_->sub : 'CODEREF',
            $_->pattern;
    } @$routes;
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
            my $mw_class = load_class($mw, 'Plack::Middleware');
            $sub = $cond ?
                Plack::Middleware::Conditional->wrap($sub, condition => $cond, builder => sub { $mw_class->wrap($_[0], %opts) }) :
                $mw_class->wrap($sub, %opts);
        }
    }

    $sub;
}

sub run {
    my ($self, $sub) = @_;
    if (ref $sub) {
        $sub->($self);
    } else {
        $self->$sub();
    }
}

sub as_psgi_app {
    my $self = ref $_[0] ? $_[0] : $_[0]->new;

    $self->wrap_middleware(sub {
        my $env = $_[0];
        my $app;
        my $sub;

        my ($route, $parameters, $code) = $self->match_route($env);

        if ($route) {
            $app = $route->app;
            $sub = $route->sub;
            $env->{'catmandu.parameters'} = $parameters;
        } else {
            $app = $self;
            given ($code) {
                when (404) { $sub = 'not_found' }
                when (405) { $sub = 'method_not_allowed' }
            }
        }

        $app->request(Plack::Request->new($env));

        $app->run($sub);

        $app->has_custom_response ?
            $app->custom_response :
            $app->response->finalize;
    });
}

sub parameters {
    $_[0]->env->{'catmandu.parameters'} ||= Hash::MultiValue->new;
}

sub has_parameters {
    defined $_[0]->env->{'catmandu.parameters'};
}

sub param {
    my ($self, $key) = @_;

    if ($key) {
        return $self->parameters->get_all($key) if wantarray;
        return $self->parameters->get($key);
    }

    keys %{$self->parameters};
}

sub object {
    my ($self, $key) = @_;

    my $obj = {};

    for my $hash (($self->req->parameters, $self->parameters)) {
        for my $obj_key (grep /^$key\./, keys %$hash) {
            my $val = $hash->get($obj_key);
            $obj_key =~ s/^$key\.//;
            $obj->{$obj_key} = $val;
        }
    }

    expand_hash($obj);
}

sub has_session {
    defined $_[0]->session;
}

sub clear_session {
    my $session = $_[0]->session or return;
    for my $key (keys %$session) {
        delete $session->{$key};
    }
    $session;
}

sub response {
    $_[0]->env->{'catmandu.response'} ||= Plack::Response->new(200, ['Content-Type' => 'text/html']);
}

alias res => 'response';

sub redirect {
    my ($self, @args) = @_; $self->response->redirect(@args);
}

sub custom_response {
    if ($_[1]) {
        $_[0]->env->{'catmandu.response.custom'} = $_[1];
    } else {
        $_[0]->env->{'catmandu.response.custom'};
    }
}

sub has_custom_response {
    exists $_[0]->env->{'catmandu.response.custom'};
}

sub clear_custom_response {
    delete $_[0]->env->{'catmandu.response.custom'};
}

sub method_not_allowed {
    $_[0]->custom_response([ 405, ['Content-Type' => "text/plain"], ["Method Not Allowed"] ]);
}

sub not_found {
    $_[0]->custom_response([ 404, ['Content-Type' => "text/plain"], ["Not Found"] ]);
}

sub print {
    my $self = shift;
    my $body = $self->res->body || [];
    push @$body, map Encode::encode_utf8($_), @_;
    $self->res->body($body);
}

sub print_template {
    my ($self, $tmpl, $vars) = @_;
    $vars ||= {};
    $vars->{app} = $self;
    Catmandu->print_template($tmpl, $vars, $self);
}

sub path_for {
    my $self = shift;
    my $name = shift;
    my $opts = ref $_[-1] eq 'HASH' ? pop : { @_ };

    if (my ($route) = grep { $_->named and $_->sub eq $name } $self->router->route_list) {
        return $route->path_for($opts);
    }
    return;
}

sub uri_for {
    my $self = shift;
    my $path = $self->path_for(@_) // return;
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
    $uri->scheme($env->{'psgi.url_scheme'});
    $uri->authority($env->{HTTP_HOST} // "$env->{SERVER_NAME}:$env->{SERVER_PORT}");
    $uri->path($env->{SCRIPT_NAME} // '/');
    $uri->canonical;
}

__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::Aliases;
no List::Util;
no Catmandu::Util;
no Hash::Merge::Simple;
no CGI::Expand;

1;

