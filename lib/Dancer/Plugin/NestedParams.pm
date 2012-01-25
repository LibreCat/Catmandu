package Dancer::Plugin::NestedParams;

our $VERSION = '0.1';

use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use CGI::Expand qw(expand_hash);

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
