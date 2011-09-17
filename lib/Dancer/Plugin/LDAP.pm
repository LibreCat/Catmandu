package Dancer::Plugin::LDAP;
use strict;
use warnings;
use Dancer::Plugin;
use Net::LDAP qw(LDAP_SUCCESS);

our $VERSION = '0.1';

my $setting = plugin_setting;
my $search_setting = $setting->{search} || {};

sub ldap {
    my $ldap_opts = $setting->{options} || {};
    my $bind_opts = $setting->{bind}    || {};
    my $ldap = Net::LDAP->new($setting->{host}, %$ldap_opts);
    my $bind;
    if ($setting->{base}) {
        $bind = $ldap->bind($setting->{base}, %$bind_opts);
    } else {
        $bind = $ldap->bind(%$bind_opts);
    }
    return unless $bind->code == LDAP_SUCCESS;
    $ldap;
}

sub ldap_search {
    my %args = (%$search_setting, @_);
    $args{attrs} ||= [];
    my $f = $args{filter};
    if (ref $f) {
        $args{filter} = '(&' . join('', map { "($_=$f->{$_})" } keys %$f) . ')';
    }

    ldap->search(%args);
}

register ldap => \&ldap;
register ldap_search => \&ldap_search;

register_plugin;

1;
