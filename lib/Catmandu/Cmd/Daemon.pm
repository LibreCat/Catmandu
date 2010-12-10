package Catmandu::Cmd::Daemon;

use namespace::autoclean;
use 5.010;
use Moose;

extends qw(Catmandu::Cmd::Command);

with qw(MooseX::Daemonize);

requires 'run_daemon';

after start => sub {
    my $self = shift;
    $self->run_daemon if $self->is_daemon;
}

sub execute {
    my ($self, $opts, $args) = @_;

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

__PACKAGE__->meta->make_immutable;

1;

