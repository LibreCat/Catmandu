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

with qw(
    MooseX::SingletonMethod::Role
    MooseX::Traits
);

my $RESPONSE_KEY = "catmandu.response";
my $CUSTOM_RESPONSE_KEY = "catmandu.response.custom";
my $PARAMETERS_KEY = "catmandu.parameters";

has '+_trait_namespace' => (default => 'Catmandu::App::Plugin');

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

    $opts{handler} ||= delete($opts{run}) || delete($opts{to});

    $opts{app} = $self;

    if ($opts{methods}) {
        $opts{methods} = [map uc, @{$opts{methods}}];
    }

    if (my $name = delete $opts{as}) {
        unless ($self->meta->has_method($name)) {
            $self->add_singleton_method($name => $opts{handler});
        }
        $opts{handler} = $name;
    }

    push @{$self->routes}, Catmandu::App::Route->new(%opts);

    $self;
}

alias R => 'route';

sub mount {
    my ($self, $pattern, $app, $defaults) = @_;

    $app = load_class($app)->new unless ref $app;

    $defaults ||= {};

    push @{$self->routes}, map {
        Catmandu::App::Route->new(
            app => $_->app,
            pattern => $pattern . $_->pattern,
            handler => $_->handler,
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
    my ($self, $request) = @_;

    my $error_code = 404;

    my $method = $request->method || '';
    my $path   = $request->path_info;
    $path =~ s!(.+)/$!$1!;

    for my $route (@{$self->routes}) {
        my @captures = $path =~ $route->pattern_regex or next;

        if (my $re = $route->methods_regex) {
            if ($method !~ $re) {
                $error_code = 405;
                next;
            }
        }

        my $parameters = Hash::MultiValue->new;
        my $components = $route->components;

        for my $i (0..@$components-1) {
            $parameters->add($components->[$i], $captures[$i]);
        }

        if ($route->has_defaults) {
            my $defaults = $route->defaults;
            for my $key (keys %$defaults) {
                $parameters->get($key) // $parameters->add($defaults->{$key});
            }
        }

        return $route, $parameters, 200;
    }

    return undef, undef, $error_code;
}

sub inspect_routes {
    my $self = shift;

    my $routes = $self->routes;

    my $max_a = max(map { length ref $_->app } @$routes);
    my $max_m = max(map { length join(',', $_->method_list) } @$routes);
    my $max_s = max(map { length $_->name } @$routes);

    join '', map {
        sprintf "%-${max_a}s %-${max_m}s %-${max_s}s %s\n",
            ref $_->app,
            join(',', $_->method_list),
            $_->name,
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
    my ($self, $handler) = @_;
    if (ref $handler) {
        $handler->($self);
    } else {
        $self->$handler();
    }
}

sub as_psgi_app {
    my $self = ref $_[0] ? $_[0] : $_[0]->new;

    $self->wrap_middleware(sub {
        my $env = $_[0];
        my $request = Plack::Request->new($env);

        my ($route, $parameters, $http_status) = $self->match_route($request);

        my $app;
        my $handler;

        if ($route) {
            $app     = $route->app;
            $handler = $route->handler;
            $env->{'catmandu.parameters'} = $parameters;
        } else {
            $app = $self;
            given ($http_status) {
                when (404) { $handler = 'not_found' }
                when (405) { $handler = 'method_not_allowed' }
            }
        }

        $app->request($request);

        $app->run($handler);

        $app->has_custom_response ?
            $app->custom_response :
            $app->response->finalize;
    });
}

sub parameters {
    $_[0]->env->{$PARAMETERS_KEY} ||= Hash::MultiValue->new;
}

sub has_parameters {
    defined $_[0]->env->{$PARAMETERS_KEY};
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
    $_[0]->env->{$RESPONSE_KEY} ||= Plack::Response->new(200, ['Content-Type' => 'text/html']);
}

alias res => 'response';

sub redirect {
    my ($self, @args) = @_; $self->response->redirect(@args);
}

sub custom_response {
    if ($_[1]) {
        $_[0]->env->{$CUSTOM_RESPONSE_KEY} = $_[1];
    } else {
        $_[0]->env->{$CUSTOM_RESPONSE_KEY};
    }
}

sub has_custom_response {
    exists $_[0]->env->{$CUSTOM_RESPONSE_KEY};
}

sub clear_custom_response {
    delete $_[0]->env->{$CUSTOM_RESPONSE_KEY};
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

sub uri {
    my $self = shift;
    my $params = ref $_[-1] ? pop : undef;
    my $name = shift;
    my $uri = $self->request->base;

    if ($name) {
        if ($name =~ /^\//) {
            $uri->path($uri->path . $name);
        } elsif (my ($route) = grep { $_->named and $_->sub eq $name } @{$self->routes}) {
            $params ||= {};
            while (my ($key, $value) = each %{$route->defaults}) {
                $params->{$key} //= $value;
            }

            my $splats = $params->{splat} || [];
            my $path = "";

            for my $part (@{$route->parts}) {
                if (ref $part) {
                    if ($part->{key} eq 'splat') {
                        $path .= shift(@$splats) // return;
                    } else {
                        $path .= delete($params->{$part->{key}}) // return;
                    }
                } else {
                    $path .= $part;
                }
            }

            $uri->path($uri->path . $path);
        } else {
            return;
        }
    }

    if ($params) {
        $uri->query_form($params);
    }

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

=head1 METHODS

=head2 new()

Constructs a new L<Catmandu::App> instance.

=head2 stash()

The stash hashref can be used to hold application
data that persists between requests.

    $self->stash->{foo} = "bar"

=head2 set($key, $value)

Sets C<$key> to C<$value> in the stash.

    $self->set('foo', 'bar')

=head2 env()

The C<PSGI> environment hashref.

    $self->env->{REQUEST_URI}

=head2 request()

The C<Plack::Request> object.

=head2 req()

Alias for C<request>.

=head2 parameters()

Returns or creates a L<Hash::MultiValue> object with
matched route and other parameters for the current request.
Query and body parameters are found in request.

    $self->parameters->get_all('foo')
    # ("bar", "baz")
    $self->parameters->get('foo')
    # "baz"

=head2 has_parameters()

Returns 1 if there is a parameters object, 0 otherwise.

=head2 param()

Returns parameters with a CGI.pm-compatible param method.
This is an alternative method for accessing parameters.
Unlike CGI.pm, it does not allow setting or modifying parameters.
Query and body parameters are found in request.

    $value = $self->param('foo');
    @values = $self->param('foo');
    @keys = $self->param;

=head2 object()



=head2 session()

See L<Plack::Request>.

=head2 has_session()

Returns 1 if there is a session hashref, 0 otherwise.

=head2 clear_session()

Deletes all key/value pairs from the session hashref.

=head2 session_options()

See L<Plack::Request>.

=head2 response()

creates or return the C<Plack::Response> object.

=head2 res()

Alias for C<response>.

=head2 redirect($url, [$status])

See L<Plack::Response>.

=head2 custom_response()

Sets or replaces a custom PSGI response. This is faster than
creating and finalizing a response object.

    $self->custom_response([ 404, ['Content-Type' => "text/plain"], ["Not Found"] ]);

=head2 has_custom_response()

Returns 1 if there is a custom repsonse, 0 otherwise.

=head2 clear_custom_response()

Clears the custom response if there is one.

=head2 method_not_allowed()

This method gets called if the requested route is found, but the
HTTP method doesn't match. Sets a custom response with HTTP
status 405. You can override this method with your own logic.

=head2 not_found()

This method gets called if the requested route isn't found. Sets
a custom response with HTTP status 404. You can override this
method with your own logic.

    sub not_found {
        my $self = shift;
        $self->print_template('404');
    }

    before run => sub {
        my ($self, $sub) = @_;
        if ($sub eq 'not_found') {
            ...
        }
    }

=head2 print(@strings)

utf-8 encodes and adds C<@strings> to the response body.

=head2 print_template($template, \%variables)

Renders C<$template> and prints it to the response body.

    $self->print_template('foo_bar', {foo => 'bar'}).

The C<app> and C<catmandu> variables will be set to C<$self> and L<Catmandu> and
passed to the first 'foo_bar.tt' template found in the template stack.

=head2 uri([$path, \%params])

Returns the uri for a named route if path is a route name, constructs a uri
with $path or returns the base uri otherwise. Params that are part
of the route pattern get filled in (or their defaults), other params are
treated as HTTP query params.

    $app->uri
    # "http://localhost:5000/app"
    $app->uri({foo => 'bar'})
    # "http://localhost:5000/app?foo=bar"
    $app->uri('/path', {foo => 'bar'})
    # "http://localhost:5000/app/path?foo=bar"
    $app->route('/users/:name', run => sub { ... }, as => 'show_user')
    $app->uri('show_user', {name => 'nicolas', foo => 'bar'})
    # "http://localhost:5000/app/users/nicolas?foo=bar"

=head2 route($pattern, %options)



=head2 R($pattern, %options)

Alias for C<route>.

=head2 GET($pattern, %options)

Same as C<route> but sets the C<methods> option to C<['GET', 'HEAD']>.

=head2 PUT($pattern, %options)

Same as C<route> but sets the C<methods> option to C<['PUT']>.

=head2 POST($pattern, %options)

Same as C<route> but sets the C<methods> option to C<['POST']>.

=head2 DELETE($pattern, %options)

Same as C<route> but sets the C<methods> option to C<['DELETE']>.

=head2 mount()



=head2 inspect_routes()

Returns an overview of the app's routes in a string.

=head2 middleware()



=head2 run()

Wraps the current request handler. Useful to hook
into every request handled.

    around run => sub {
        my ($run, $app, $handler) = @_;
        # do stuff
        $app->$run($handler);
        # do stuff
    };

An app basically handles every request like this:

    $app->request($request)     # set current request
    $app->run($sub)             # set current handler
    $app->has_custom_response ? # return response
        $app->custom_response :
        $app->response->finalize;

=head2 as_psgi_app()

Returns the app as a L<PSGI> application (a coderef which
accepts an C<env> hashref).

=head1 SEE ALSO

L<Plack::Request>

L<Plack::Response>

L<Hash::MultiValue>

