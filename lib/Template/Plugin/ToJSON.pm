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
