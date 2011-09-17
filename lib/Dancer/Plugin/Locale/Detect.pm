package Dancer::Plugin::Locale::Detect;
use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);
use Locale::Util;

our $VERSION = '0.1';

my $setting = plugin_setting;
my $param = exists $setting->{param} ? $setting->{param} : 'locale';
my $parse_http_accept = exists $setting->{parse_http_accept} ? $setting->{parse_http_accept} : 1;

if ($param || $parse_http_accept) {
    before sub {
        if ($param and my $loc = params->{$param}) {
            Locale::Util::web_set_locale([$loc]);
        } elsif ($parse_http_accept) {
            Locale::Util::web_set_locale(request->env->{HTTP_ACCEPT_LANGUAGE});
        }
    };
}

register_plugin;

1;
