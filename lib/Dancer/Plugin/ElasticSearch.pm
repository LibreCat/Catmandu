package Dancer::Plugin::ElasticSearch;
use strict;
use warnings;
use Dancer::Plugin;
use ElasticSearch;

our $VERSION = '0.1';

my $es;

register es => sub {
    $es ||= ElasticSearch->new(plugin_setting || {});
};

register_plugin;

1;
