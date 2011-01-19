package Catmandu::App::Web;
# VERSION
use Moose;
use MooseX::Aliases;
use Catmandu;
use Catmandu::Types qw(MultiValueHash);
use Hash::MultiValue;
use CGI::Expand;
use URI;
use Encode ();

with qw(Catmandu::App::Env);

has app => (
    is => 'ro',
    isa => 'Catmandu::App',
    required => 1,
);

has response => (
    is => 'ro',
    isa => 'Plack::Response',
    lazy => 1,
    alias => 'res',
    builder => 'new_response',
    handles => [qw(
        redirect
    )],
);

has custom_response => (
    is => 'rw',
    isa => 'ArrayRef',
    predicate => 'has_custom_response',
    clearer => 'clear_custom_response',
);

has parameters => (
    is => 'ro',
    isa => MultiValueHash,
    coerce => 1,
    default => sub { Hash::MultiValue->new },
);

sub new_response {
    $_[0]->req->new_response(200, ['Content-Type' => 'text/html']);
}

sub param {
    my ($self, $key) = @_;

    if ($key) {
        return $self->parameters->get_all($key) if wantarray;
        return $self->parameters->get($key);
    }

    keys %{$self->parameters};
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
    $vars->{app} = $self->app;
    $vars->{web} = $self;
    Catmandu->print_template($tmpl, $vars, $self);
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

sub path_for {
    my $self = shift;
    my $name = shift;
    my $opts = ref $_[-1] eq 'HASH' ? pop : { @_ };

    if (my ($route) = grep { $_->named and $_->sub eq $name } $self->app->router->route_list) {
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

no Catmandu::Types;
no MooseX::Aliases;
no Moose;
no CGI::Expand;

1;

=head1 METHODS

=head2 $c->object($key)

Gives support for nested/complex query params.
Unflattens the request params that have a key starting with C<$key>
and expands them into a deep hashref.

Given a query string
    "obj.foo=foo&foo.obj=foo&obj.bar.0=b&obj.baz.foo=bar&obj.bar.2=r"
the key "obj" gets expanded to:
    {
        foo => "foo",
        bar => ["b", undef, "r"],
        baz => { foo => "bar" },
    }

See L<CGI::Expand> for details and more examples.

