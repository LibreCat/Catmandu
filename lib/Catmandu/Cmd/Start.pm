package Catmandu::Cmd::Start;

use Moose;
use Plack::Runner;
use Plack::Util;
use Catmandu;

with 'MooseX::Getopt';

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

has reload => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Bool',
    cmd_aliases => 'r',
    documentation => "Watch the lib, psgi, conf and template directories and restart the server whenever a file changes.",
);

has server => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 's',
    documentation => "Server to run on.",
);

has app => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'a',
    default => 'app.psgi',
    documentation => "Either a .psgi script to run or a Catmandu::App. Defaults to app.psgi. " .
                     "Can also be the first non-option argument. " .
                     "The .psgi extension is optional.",
);

sub _usage_format {
    "usage: %c %o <app>";
}

sub BUILD {
    my $self = shift;
    if (my $app = $self->extra_argv->[0]) {
        $self->app($app);
    }
}

sub run {
    my $self = shift;
    my $catmandu = Catmandu->new;
    my $app = $self->app;
    my $eval;
    my $psgi;

    if ($app =~ /::/) {
        $eval = $app."->as_psgi_app";
    } else {
        $psgi = $catmandu->find_psgi($app) or confess "Can't find psgi app $app";
    }

    my @argv;
    if ($self->reload) {
        push @argv, '-r';
        push @argv, '-R', join(',', $catmandu->catmandu_lib,
                                    $catmandu->lib,
                                    $catmandu->path_list('conf'),
                                    $catmandu->path_list('psgi'),
                                    $catmandu->path_list('template'));
    }
    push @argv, map { ('-I', $_) } $catmandu->lib;
    push @argv, '-E', $catmandu->env;
    push @argv, '-p', $self->port   if $self->port;
    push @argv, '-o', $self->host   if $self->host;
    push @argv, '-S', $self->socket if $self->socket;
    push @argv, '-D'                if $self->daemonize;
    push @argv, '-s', $self->server if $self->server;
    push @argv, '-a', $psgi         if $psgi;
    push @argv, '-e', $eval         if $eval;
    push @argv, '-M', $app          if $eval;
    Plack::Runner->run(@argv);
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

