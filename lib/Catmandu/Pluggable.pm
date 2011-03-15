package Catmandu::Pluggable;
use Catmandu::Sane;
use Catmandu::Util qw(create_package load_package add_parent
    get_subroutine add_subroutine);

sub plugin_namespace {
    confess "Not implemented";
}

sub load_plugins {
    my ($pkg, @plugins) = @_;

    my $ns = $pkg->plugin_namespace;

    while (my $plugin = shift @plugins) {
        $plugin = load_package($plugin, $ns);
        {
            no strict 'refs';
            for my $sym (@{"${plugin}::EXPORT_PLUGIN"}) {
                add_subroutine($pkg, $sym => get_subroutine($plugin, $sym)) unless $pkg->can($sym);
            }
        };
        if ($plugin->can('import_plugin')) {
            $plugin->import_plugin($pkg, ref $plugins[0] eq 'HASH' ? shift @plugins : {});
        }
    }
    for my $plugin (@plugins) {
        $plugin = load_package($plugin, $ns);
    }
}

sub with_plugins {
    my ($pkg, @plugins) = @_;
    my $new = create_package;
    add_parent($new, $pkg);
    $new->load_plugins(@plugins);
    $new;
}

no Catmandu::Util;
1;
