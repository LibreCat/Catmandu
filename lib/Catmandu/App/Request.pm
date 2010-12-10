package Catmandu::App::Request;

use strict;
use warnings;
use namespace::autoclean;
use parent 'Plack::Request';
use Catmandu::App::Response;
use CGI::Expand;

sub new_response {
    my ($self, @arg) = @_;
    Catmandu::App::Response->new(@arg);
}

sub expand_param {
    my ($self, $key) = @_;
    my $params = $self->parameters;
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

1;

__END__

=head1 NAME

Catmandu::App::Request - class representing a HTTP request.

=head1 DESCRIPTION

This is subclass of L<Plack::Request>. You shouldn't create instances
of this class explicitly. Instances are created on each HTTP request
and passed to the L<Catmandu::App> instance handling the request.

=head1 METHODS

See L<Plack::Request> for the inherited methods.

Extra methods for this class:

=head2 $c->expand_param($key)

Gives support for nested query params.
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

=head1 SEE ALSO

L<Plack::Request>, the superclass.

L<CGI::Expand>.

