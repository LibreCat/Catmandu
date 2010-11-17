package Catmandu::App;

use Moose ();
use Moose::Exporter;
use Catmandu::App::Role::Object;

Moose::Exporter->setup_import_methods(
    as_is => [qw(any get put post delete set enable enable_if mount)],
    also => 'Moose',
);

sub init_meta {
    shift;
    my %args = @_;
    my $caller = $args{for_class};
    Moose->init_meta(%args);
    Moose::Util::apply_all_roles($caller, 'Catmandu::App::Role::Object');
    $caller->meta;
}

sub any {
    my $caller = caller;
    if (@_ == 3) {
        my ($methods, $route, $sub) = @_;
        $caller->add_route($route, $sub, method => [ map { uc $_ } @$methods ]);
    } else {
        my ($route, $sub) = @_;
        $caller->add_route($route, $sub);
    }
}

sub get { my $caller = caller; $caller->add_route(@_, method => ['GET', 'HEAD']); }
sub put { my $caller = caller; $caller->add_route(@_, method => ['PUT']); }
sub post { my $caller = caller; $caller->add_route(@_, method => ['POST']); }
sub delete { my $caller = caller; $caller->add_route(@_, method => ['DELETE']); }

sub set { my $caller = caller; $caller->stash(@_); };

sub enable { my $caller = caller; $caller->add_middleware(@_); }
sub enable_if(&$@) { my $caller = caller; $caller->add_middleware_if(@_); }
sub mount { my $caller = caller; $caller->add_mount(@_); }

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
    __PACKAGE__->add_route('/foo', sub { ... }, method => ['GET', 'POST']);
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
C<$route> must be a valid L<Router::Simple> rule.

    sub foo {
        ...
    }
    any [qw(get post)] => '/foo' => 'foo';
    any [qw(get post)] => '/foo' => sub { ... };
    any '/foo' => sub { ... };

=head2 get($route, $sub)

Same as C<any(['GET', 'HEAD'], $route, $sub)>.

=head2 post($route, $sub)

Same as C<any(['POST'], $route, $sub)>.

=head2 put($route, $sub)

Same as C<any(['PUT'], $route, $sub)>.

=head2 delete($route, $sub)

Same as C<any(['DELETE'], $route, $sub)>.

=head2 enable($middleware, %options)

Enables L<Plack::Middleware>.

    enable 'StackTrace', force => 1;

=head2 enable_if($block, $middleware, %options)

Conditionaly enables L<Plack::Middleware>.

    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'StackTrace';

=head2 mount($path | $url, $sub)

Uses L<Plack::App::URLMap> to mount C<$sub> at the specified C<$path>
or C<$url>. C<$sub> can be a coderef or another L<Catmandu::App>.

    mount '/foo' => FooApp;
    mount 'http://bar/' => 'BarApp';

=head1 SEE ALSO

L<Router::Simple>.

L<Catmandu::App::Request>.

L<Plack::Response>.

L<Plack::Middleware>.

L<Plack::Middleware::Conditional>.

L<Plack::App::URLMap>.

L<Plack::Builder>.

