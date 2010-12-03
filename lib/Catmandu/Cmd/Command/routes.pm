use MooseX::Declare;

class Catmandu::Cmd::Command::routes extends Catmandu::Cmd::Command {
    use Plack::Util;

    has psgi_app => (
        traits => ['Getopt'],
        is => 'rw',
        isa => 'Str',
        cmd_flag => 'app',
        cmd_aliases => 'a',
        documentation => "A Catmandu::App. Can also be the first non-option argument.",
    );

    method execute ($opts, $args) {
        my $app = shift @$args || $self->psgi_app;
        Plack::Util::load_class($app);
        print $app->inspect_routes;
    }
}

1;

