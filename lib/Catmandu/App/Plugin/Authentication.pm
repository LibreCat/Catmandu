package Catmandu::App::Plugin::Authentication;
use Catmandu::Sane;
use Catmandu::Authentication;

our @EXPORT_PLUGIN = qw(
    authentication
);

sub authentication {
    $_[0]->env->{'catmandu.authentication'};
}

sub import_plugin {
    my ($plugin, $app, $opts) = @_;
    $app->add_middleware('Catmandu::Authentication', $opts);
}

1;

