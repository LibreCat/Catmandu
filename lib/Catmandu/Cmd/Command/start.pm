package Catmandu::Cmd::Command::start;
# VERSION
use namespace::autoclean;
use Moose;
use Catmandu;
use Plack::Runner;
use Plack::Util;

extends qw(Catmandu::Cmd::Command);

has host => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'o',
    documentation => "The interface a TCP based server daemon binds to. Defaults to any (*).",
);

has port => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Int',
    lazy => 1,
    cmd_aliases => 'p',
    default => 5000,
    documentation => "The port number a TCP based server daemon listens on. Defaults to 5000.",
);

has socket => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'S',
    documentation => "UNIX domain socket path to listen on. Defaults to none.",
);

has daemonize => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    cmd_aliases => 'D',
    documentation => "Makes the process go background. Not all servers respect this option.",
);

has loader => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'L',
    documentation => "Reloads on every request if 'Shotgun'. " .
                    "Delays compilation until the first request if 'Delayed'.",
);

has server => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 's',
    documentation => "Server to run on.",
);

has psgi_app => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    cmd_flag => 'app',
    cmd_aliases => 'a',
    default => 'app.psgi',
    documentation => "Either a .psgi script to run or a Catmandu::App. Defaults to app.psgi.",
);

sub execute {
    my ($self, $opts, $args) = @_;

    my $app = $args->[0] || $self->psgi_app;

    my @argv;
    if ($app =~ /\.psgi$/) {
        $app = Catmandu->file('psgi', $app) or die "Can't find psgi app $app";
        push @argv, '-a', $app;
    } else {
        push @argv, '-e', "use $app; $app->to_app";
    }
    push @argv, map { ('-I', $_) } Catmandu->lib;
    push @argv, '-E', Catmandu->env;
    push @argv, '-Moose';
    push @argv, '-p', $self->port   if $self->port;
    push @argv, '-o', $self->host   if $self->host;
    push @argv, '-S', $self->socket if $self->socket;
    push @argv, '-D'                if $self->daemonize;
    push @argv, '-L', $self->loader if $self->loader;
    push @argv, '-s', $self->server if $self->server;
    Plack::Runner->run(@argv);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catmandu::Cmd::Command::start - start a Catmandu::App's server


