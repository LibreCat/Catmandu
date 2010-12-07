package Catmandu::App;

use Moose ();
use Moose::Exporter;
use Catmandu::App::Object;
use Catmandu;

Moose::Exporter->setup_import_methods(
    also  => 'Moose',
    as_is => [\&Catmandu::project, qw(
        any
        get
        put
        post
        delete
        set
        enable
        enable_if
        mount
    )],
);

sub init_meta {
    shift;
    my %args = @_;
    my $caller = $args{for_class};
    Moose->init_meta(%args);
    Moose::Util::apply_all_roles($caller, 'Catmandu::App::Object');
    $caller->meta;
}

sub any {
    my $caller = caller;
    if (ref $_[0] eq 'ARRAY') {
        my $methods = shift;
        $caller->add_route(@_, { method => [ map { uc $_ } @$methods ] });
    } else {
        $caller->add_route(@_);
    }
}

sub get    { my $caller = caller; $caller->add_route(@_, { method => ['GET', 'HEAD'] }); }
sub put    { my $caller = caller; $caller->add_route(@_, { method => ['PUT'] }) ; }
sub post   { my $caller = caller; $caller->add_route(@_, { method => ['POST'] }); }
sub delete { my $caller = caller; $caller->add_route(@_, { method => ['DELETE'] }); }

sub set { my $caller = caller; $caller->stash(@_); };

sub enable         { my $caller = caller; $caller->add_middleware(@_); }
sub enable_if(&$@) { my $caller = caller; $caller->add_middleware_if(@_); }
sub mount          { my $caller = caller; $caller->add_mount(@_); }

__PACKAGE__;

__END__

=head1 NAME

Catmandu::App

=head1 SYNOPSIS

    package FooApp;

    use Catmandu::App;

    # set stash values
    set foo => 'bar';

    # define routes
    get '/echo/:name' => sub {
        my $self = shift;
        $self->print($self->param('name'));
    };

    any [qw(get post)] => '/foo' => sub { ... };
    any '/foo' => sub { ... };

    sub echo {
        my $self = shift;
        ...
    }
    get '/echo/:name' => 'echo';

    # enable Plack middleware
    enable "Header", 'X-Foo' => 1;
    enable_if { my $env = shift; ... } 'Header', 'X-Foo' => 1;

    # mount other psgi apps
    mount '/bar', 'BarApp';
    mount '/baz', sub { [200, ['Content-Type' => 'text/plain'], ['baz']] };

    # without the sugar
    __PACKAGE__->stash(foo => 'bar');
    __PACKAGE__->stash(foo);
    __PACKAGE__->add_route('/foo', 'foo', sub { ... }, {method => ['GET', 'POST']});
    __PACKAGE__->add_route('/foo', sub { ... }, {method => ['GET', 'POST']});
    __PACKAGE__->add_middleware("Header", 'X-Foo' => 1);
    __PACKAGE__->add_mount('/bar', 'BarApp');

    # the psgi app
    __PACKAGE__->to_app;

    1;

    sub {
        my $self = shift;

        my $foo = $self->stash('foo');

        my $foo = $self->param('foo');

        my $foo = $self->request->param('foo');

        $self->request->expand_param('obj');

        my $foo = $self->request->session->{foo};
        my $foo = $self->session->{foo};

        my $hash_ref = $self->request->cookies;

        $self->request->header('Accept');

        $self->response->content_type('application/json');

        $self->response->header('Accept' => [qw(text/html text/plain image/*)]);

        $self->response->cookies;

        $self->print("text", "in", "body");

        $self->print_template("foo", {foo => 'bar'});

        $self->redirect($url);
    }

=head1 SUGAR FUNCTIONS

=head2 set($key, $val)

Sets the C<$key> to C<$val> in the app's stash.

=head2 any([$methods], $route, $sub)

Connects the route C<$route> to C<$sub> for the chosen HTTP methods.
C<$sub> be either a coderef that takes an app instance
or the name of a method of the app.
See L<Router::Simple> for possible values of C<$route>.

    sub foo {
        ...
    }
    any [qw(get post)] => '/foo' => 'foo';
    any [qw(get post)] => '/foo' => sub { ... };
    any '/foo' => sub { ... };

Also see the method C<add_route> for a more flexible
way to add routes.

=head2 get($route, $sub)

Same as C<any(['GET', 'HEAD'], $route, $sub)>.

=head2 post($route, $sub)

Same as C<any(['POST'], $route, $sub)>.

=head2 put($route, $sub)

Same as C<any(['PUT'], $route, $sub)>.

=head2 delete($route, $sub)

Same as C<any(['DELETE'], $route, $sub)>.

=head2 enable($middleware, [%opts])

Enables L<Plack::Middleware>.

    enable 'StackTrace', force => 1;

=head2 enable_if($block, $middleware, [%opts])

Conditionaly enables L<Plack::Middleware>.

    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'StackTrace';

=head2 mount($path|$url, $sub)

Uses L<Plack::App::URLMap> to mount C<$sub> at the specified C<$path>
or C<$url>. C<$sub> can be a coderef or another L<Catmandu::App>.

    mount '/foo' => FooApp;
    mount 'http://bar/' => 'BarApp';

=head1 METHODS

=head2 $c->request

The current L<Catmandu::App::Request>, a subclass of L<Plack::Request>.

=head2 $c->req

Shorthand for C<request>.

=head2 $c->response

The current L<Plack::Response>.

=head2 $c->res

Shorthand for C<response>.

=head2 $c->session

See L<Plack::Request>.

=head2 $c->env

See L<Plack::Request>.

=head2 $c->redirect($path|$url, [$status])

See L<Plack::Response>.

=head2 $c->params

The params hashref contains the matched route variables
and any other state you wich to hold for the duration of the
current request.

=head2 $c->param($key, [$val], [%more])

Returns the C<params> hashref if called with no arguments. Returns C<$key>
in C<params> if called with one argument. If called with more arguments,
C<param> will set the key/value pair or pairs in C<params>.

=head2 $c->print(\@args)

Prints the values of C<@args> to the HTTP response body. Since it only appends,
C<print> can be called multiple times to gradually build the response
text.

=head2 $c->print_template($tmpl, [\%vars])

Processes template C<$tmpl> with the variables in C<%vars>
and prints the result to the response body.

=head2 Class|$c->stash($key, [$val], [%more])

The stash hashref holds state that needs to persist between
requests.

=head2 $c->run($sub)

In combination with the L<Moose method modifiers|Moose::Manual::MethodModifiers>
run allows you to add before|around|after hooks to the handling of the request.

    around run => sub {
        my ($run, $self, $sub) = @_;
        # do stuff
        $self->$run($sub); # or do something else
        # do stuff
    }


=head2 Class|$c->add_middleware($middleware, [%opts])

See C<enable>.

=head2 Class|$c->add_middleware_if($block, $middleware, [%opts])

See C<enable_if>.

=head2 Class|$c->add_route($route, $sub, [%opts])

Connects the route C<$route> to C<$sub>.
C<$sub> can either be a coderef that takes an app instance
or the name of a method of the app.
See L<Router::Simple> for possible values of C<$route> and C<%opts>.

=head2 Class|$c->add_mount($path|$url, $sub)

See C<mount>.

=head2 Class|$c->to_app

Returns the app as a coderef runnable with any psgi
capable server.

=head2 Class|$c->inspect_routes

Shows a string representation of the routes matched
by the app.

=head1 SEE ALSO

L<Router::Simple>.

L<Catmandu::App::Request>.

L<Plack::Response>.

L<Plack::Middleware>.

L<Plack::Middleware::Conditional>.

L<Plack::App::URLMap>.

L<Plack::Builder>.

