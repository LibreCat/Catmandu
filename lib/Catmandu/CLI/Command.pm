package Catmandu::CLI::Command;
use Catmandu::Sane;
use parent qw(
    App::Cmd::Command
);

sub opt_spec {
    my ($class, $app) = @_;
    (
        [ 'help|h|?', "this usage screen" ],
        $app->global_opt_spec,
        [ ],
        $class->command_opt_spec($app),
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    if ($opts->{help}) {
        print $self->usage->text;
        exit;
    }

    $self->command($opts, $args);
}

sub command_opt_spec {}
sub command {}

1;
