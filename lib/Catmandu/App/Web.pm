package Catmandu::App::Web;
# VERSION
use Moose;
use Moose::Util::TypeConstraints;
use Catmandu;
use Catmandu::App::Env;
use Hash::MultiValue;
use CGI::Expand;
use Encode ();

with qw(Catmandu::App::Env);

subtype 'Catmandu::App::Web::Parameters'
    => as 'Object'
    => where { $_->isa('Hash::MultiValue') };

coerce 'Catmandu::App::Web::Parameters'
    => from 'ArrayRef'
    => via { Hash::MultiValue->new(@$_) };

coerce 'Catmandu::App::Web::Parameters'
    => from 'HashRef'
    => via { Hash::MultiValue->from_mixed($_) };

has app => (
    is => 'ro',
    isa => 'Catmandu::App',
    required => 1,
);

has res => (
    is => 'ro',
    isa => 'Plack::Response',
    lazy => 1,
    builder => 'new_response',
    handles => [qw(
        redirect
    )],
);

has parameters => (
    is => 'ro',
    isa => 'Catmandu::App::Web::Parameters',
    coerce => 1,
    required => 1,
);

sub new_response {
    $_[0]->req->new_response(200, ['Content-Type' => 'text/html']);
}

sub response {
    $_[0]->res;
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
    my $params = $self->req->parameters;
    my @keys = grep /^$key\./, keys %$params;
    @keys or return;
    my $flat = {};
    foreach my $flat_key (@keys) {
        my $value = $params->get($flat_key);
        $flat_key =~ s/^$key\.//;
        $flat->{$flat_key} = $value;
    }
    expand_hash($flat);
}

__PACKAGE__->meta->make_immutable;

no Moose::Util::TypeConstraints;
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

