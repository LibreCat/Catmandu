package Catmandu::App::Request;

use strict;
use warnings;
use base 'Plack::Request';
use CGI::Expand ();

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
    CGI::Expand->expand_hash($flat);
}

__PACKAGE__;

