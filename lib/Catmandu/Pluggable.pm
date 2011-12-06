package Catmandu::Pluggable;

use Catmandu::Sane;
use Role::Tiny;

my $PLUGIN_NAMESPACE = 'Catmandu::Plugin';

sub with_plugins {
    my $class = shift;
    my @plugins = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    @plugins || return $class;
    @plugins = map {
        my $pkg = $_;
        if ($pkg !~ s/^\+// && $pkg !~ /^$PLUGIN_NAMESPACE/) {
            $pkg = "${PLUGIN_NAMESPACE}::${pkg}";
        }
        $pkg;
    } @plugins;
    Role::Tiny->create_class_with_roles($class, @plugins);
}

1;
