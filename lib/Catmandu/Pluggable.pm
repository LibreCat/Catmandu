package Catmandu::Pluggable;

use Catmandu::Sane;
use Role::Tiny;
use namespace::clean;

sub plugin_namespace { 'Catmandu::Plugin' }

sub with_plugins {
    my $class = shift;
    $class = ref $class || $class;
    my @plugins = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    @plugins = split /,/, join ',', @plugins;
    @plugins || return $class;
    my $ns = $class->plugin_namespace;
    Role::Tiny->create_class_with_roles($class, map {
        my $pkg = $_;
        if ($pkg !~ s/^\+// && $pkg !~ /^$ns/) {
            $pkg = "${ns}::${pkg}";
        }
        $pkg;
    } @plugins);
}

1;
