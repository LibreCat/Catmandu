package Dancer::Plugin::NestedParams;
use strict;
use warnings;
use Dancer qw(:syntax);
use Dancer::Plugin;
use CGI::Expand qw(expand_hash);

our $VERSION = '0.1';

register expand_params => sub {
    my $source = shift;
    my $params = $source ? params($source) : params;

    expand_hash($params);
};

register expand_param => sub {
    my $key    = pop;
    my $source = pop;
    my $params = $source ? params($source) : params;

    expand_hash($params)->{$key};
};

register_plugin;

1;
