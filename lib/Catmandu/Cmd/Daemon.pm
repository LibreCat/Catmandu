use MooseX::Declare;

class Catmandu::Cmd::Daemon extends Catmandu::Cmd::Command with MooseX::Daemonize {
    requires 'run_daemon';

    after start () {
        $self->run_daemon if $self->is_daemon;
    }

    method execute ($opts, $args) {
        given ($args->[0]) {
            when ('start')   { $self->start }
            when ('stop')    { $self->stop }
            when ('restart') { $self->restart }
            when ('status')  { $self->status }
            default {
                $self->usage->die;
            }
        }
    }
}

1;

