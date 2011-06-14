package Catmandu::Cmd;
use Catmandu::Sane;
use parent qw(App::Cmd::Command);

sub opt_spec {
    my ($cmd_class, $cmd) = @_;
    (
        ['help|h|?', "this usage screen"],
        $cmd->global_opt_spec,
        [],
        $cmd_class->command_opt_spec($cmd),
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
