package Catmandu::Cmd;
use Catmandu::Sane;
use parent qw(App::Cmd::Command);

sub opt_spec {
    my ($class, $cli) = @_;
    (
        ['help|h|?', "this usage screen"],
        $cli->global_opt_spec,
        $class->command_opt_spec($cli),
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
