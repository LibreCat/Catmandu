package Template::Plugin::ToJSON;
use strict;
use warnings;
use parent qw(Template::Plugin);
use JSON ();

sub new {
    my ($class, $context) = @_;
    my $json = JSON->new;
    $context->define_vmethod($_, to_json => sub { $json->encode(@_) }) for qw(hash list scalar);
    $json;
}

1;

=head1 NAME

Template::Plugin::ToJSON - Template plugin that adds a .to_json vmethod

=head1 SYNOPSIS

    [% USE ToJSON %]

    <script type="text/javascript">
        var foo = [% foo.to_json %];
    </script>

    [% USE json = ToJSON %]

    [% bar = json.decode(foo) %]
    [% foo = json.encode(bar) %]

=head1 DESCRIPTION

Template plugin that adds a .to_json vmethod to all values.

This plugin provides the same functionality as L<Template::Plugin::JSON>,
but isn't dependent on L<Moose>.

=head1 SEE ALSO

L<Template::Plugin::JSON>.

=cut
