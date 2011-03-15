package Catmandu::App;
use Catmandu::Sane;
use Catmandu::Util qw(add_parent get_subroutine_info add_subroutine trim unquote);

sub base { 'Catmandu::App::Base' }

sub import {
    my ($self) = @_;

    my $caller = caller;

    Catmandu::Sane->import(level => 2);

    my $stash = {};
    my $render_vars = {app => $caller};
    my $middlewares = [];
    my $mounts = [];
    my $routes = [];
    my @code_attribute_routes;
    my $env;
    my $request;

    add_parent($caller, $self->base);

    add_subroutine($caller,
        app         => sub { $caller },
        stash       => sub { $stash },
        render_vars => sub { $render_vars },
        middlewares => sub { $middlewares },
        mounts      => sub { $mounts },
        handle      => sub { $request = $_[0]->new_request($env = $_[1]) },
        env         => sub { $env     || confess("Not running") },
        request     => sub { $request || confess("Not running") },
        routes      => sub {
            if (@code_attribute_routes) {
                my $app = $_[0];
                while (my $info = shift @code_attribute_routes) {
                    my ($sub, $pattern, $opts) = @$info;
                    my ($pkg, $sym) = get_subroutine_info($app, $sub);
                    $opts->{handler} = $sym;
                    $app->add_route($pattern || "/$sym", $opts);
                }
            }
            $routes;
        },
        MODIFY_CODE_ATTRIBUTES => sub {
            my ($pkg, $sub, @attrs) = @_;
            my @rest;
            for my $attr (@attrs) {
                if (my ($http_method) = $attr =~ /^(GET|PUT|POST|DELETE)$/) {
                    push @code_attribute_routes, [0+$sub, undef, {methods => [$http_method]}];
                    next;
                }
                if (my ($http_method, $pattern) = $attr =~ /^(GET|PUT|POST|DELETE)\((.+)\)$/) {
                    push @code_attribute_routes, [0+$sub, trim(unquote($pattern)), {methods => [$http_method]}];
                    next;
                }
                if ($attr =~ /^R$/) {
                    push @code_attribute_routes, [0+$sub, undef, {}];
                    next;
                }
                if (my ($args) = $attr =~ /^R\((.+)\)$/) {
                    my @http_methods = map { trim unquote $_ } split /,/, $args;
                    my $pattern = $http_methods[0] =~ /^GET|PUT|POST|DELETE$/ ? undef : shift @http_methods;
                    if (@http_methods) {
                        push @code_attribute_routes, [0+$sub, $pattern, {methods => [@http_methods]}];
                    } else {
                        push @code_attribute_routes, [0+$sub, $pattern, {}];
                    }
                    next;
                }

                push @rest, $attr;
            }
            @rest;
        },
    );
}

no Catmandu::Util;

package Catmandu::App::Base;
use Catmandu::Sane;
use List::Util qw(max);
use Hash::MultiValue;
use CGI::Expand ();
use Plack::Builder ();
use Catmandu;
use Catmandu::Route;
use Catmandu::Request;
use parent qw(
    Catmandu::Modifiable
    Catmandu::Pluggable
);

my $response_key = "catmandu.response";
my $custom_response_key = "catmandu.custom_response";
my $parameters_key = "catmandu.parameters";

my $http_status_codes = { # stolen from HTTP::Status
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
};

sub plugin_namespace { 'Catmandu::App::Plugin' }

sub req {
    $_[0]->request;
}

sub res {
    $_[0]->response;
}

sub get {
    $_[0]->stash->{$_[1]};
}

sub set {
    $_[0]->stash->{$_[1]} = $_[2];
}

sub response {
    my $self = $_[0];
    $self->env->{$response_key} ||= $self->req->new_response;
}

sub custom_response {
    if (@_ == 2) {
        return $_[0]->env->{$custom_response_key} = $_[1];
    }
    $_[0]->env->{$custom_response_key};
}

sub new_request {
    Catmandu::Request->new($_[1]);
}

sub parameters {
    $_[0]->env->{$parameters_key} ||= Hash::MultiValue->new;
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
    my ($self, $prefix) = @_;

    my $obj = {};

    for my $params (($self->request->parameters, $self->parameters)) {
        for my $key (grep { s/^$prefix\.// } keys %$params) {
            $obj->{$key} = $params->get($key);
        }
    }

    CGI::Expand->expand_hash($obj);
}

sub render {
    my $self = shift;
    my $tmpl = shift;
    my $vars = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    my $render_vars = $self->render_vars;
    foreach (keys %$render_vars) {
        $vars->{$_} = $render_vars->{$_} unless exists $vars->{$_};
    }
    Catmandu->render($tmpl, $vars, $self->res);
}

sub add_middleware {
    my $self = shift;
    my $mw   = shift;
    my $opts = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    my $if   = delete $opts->{if};

    push @{$self->middlewares}, [$mw, $if, $opts];

    $self;
}

sub add_mount {
    my ($self, $path, $app) = @_;
    push @{$self->mounts}, [$path, $app];
    $self;
}

sub add_route {
    my $self    = shift;
    my $pattern = shift;
    my $handler = ref $_[0] eq 'CODE' ? shift : undef;
    my $args    = ref $_[0] eq 'HASH' ? shift : {@_};

    $args->{handler} ||= $handler || delete($args->{to}) || delete($args->{run});
    $args->{pattern} = $pattern;

    if (my $as = delete($args->{as}) || delete($args->{name})) {
        { no strict 'refs'; *{$as} = $args->{handler} };
        $args->{handler} = $as;
    }

    push @{$self->routes}, Catmandu::Route->new($args);

    $self;
}

sub R {
    my $self = shift; $self->add_route(@_);
}

for my $http_methods ((['GET', 'HEAD'], ['PUT'], ['POST'], ['DELETE'])) {
    my $sym = $http_methods->[0];
    my $sub = sub {
        my $self    = shift;
        my $pattern = shift;
        my $handler = ref $_[0] eq 'CODE' ? shift : undef;
        my $args    = ref $_[0] eq 'HASH' ? shift : {@_};

        $args->{handler} ||= $handler if $handler;
        $args->{methods} = $http_methods;
        $self->add_route($pattern, $args);
        $self;
    };
    no strict 'refs'; *{$sym} = $sub;
}

sub match_route {
    my ($self, $req) = @_;
    my $status = 404;
    my $method;
    my $path = $req->path_info;
    $path =~ s!(.+)/+$!$1!; # remove trailing slashes

    for my $route (@{$self->routes}) {
        my @captures = $path =~ $route->pattern_regex or next;

        if (my $regex = $route->methods_regex) {
            $method ||= $req->parameters->{_method} || $req->method || '';
            if ($method !~ $regex) {
                $status = 405;
                next;
            }
        }

        my $keys     = $route->parameters;
        my $defaults = $route->defaults;
        my $params   = $req->env->{$parameters_key} ||= Hash::MultiValue->new;

        $params->add($keys->[$_], $captures[$_]) for (0 .. @$keys-1);

        for my $key (keys %$defaults) {
            $params->get($key) //
            $params->add($key, $defaults->{$key});
        }

        return ($route, 200);
    }

    (undef, $status);
}

sub inspect_routes {
    my $self = $_[0];

    my $max_m = max(map { length join(',', @{$_->methods}) } @{$self->routes});
    my $max_n = max(map { length $_->name } @{$self->routes});

    join '', map {
        sprintf "%-${max_m}s %-${max_n}s %s\n",
            join(',', @{$_->methods}),
            $_->name,
            $_->pattern;
    } @{$self->routes};
}

sub psgi_app {
    my $self = $_[0];
    my $builder = Plack::Builder->new;

    foreach (@{$self->middlewares}) {
        my ($mw, $if, $opts) = @$_;
        $if ? $builder->add_middleware_if($if, $mw, %$opts)
            : $builder->add_middleware($mw, %$opts);
    }

    foreach (@{$self->mounts}) {
        my ($path, $app) = @$_;
        $builder->mount($path, ref $app eq 'CODE' ? $app : $app->psgi_app);
    }

    $builder->to_app(sub {
        my ($route, $status) = $self->match_route($self->handle($_[0]));

        $self->run($route ? $route->handler : "handle_$status");
        $self->custom_response ||
            $self->response->finalize;
    });
}

sub run {
    my ($self, $handler) = @_;
    if (ref $handler) {
        $handler->($self);
    } else {
        $self->$handler();
    }
}

for my $status (grep { $_ >= 400 } keys %$http_status_codes) {
    my $msg = $http_status_codes->{$status};
    my $sym = "handle_$status";
    my $sub = sub {
        $_[0]->custom_response([ $status, ['Content-Type' => 'text/plain'], [$msg] ])
    };
    no strict 'refs'; *{$sym} = $sub;
}

no List::Util;
1;
