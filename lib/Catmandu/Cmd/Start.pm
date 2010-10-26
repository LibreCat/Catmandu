package Catmandu::Cmd::Start;

use Any::Moose;
use Plack::Runner;
use Plack::Util;
use Catmandu;

with any_moose('X::Getopt');

has host => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'o');
has port => (traits => ['Getopt'], is => 'rw', isa => 'Int', cmd_aliases => 'p');
has socket => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'S');
has daemonize => (traits => ['Getopt'], is => 'rw', isa => 'Bool', cmd_aliases => 'D');
has server => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 's');
has app => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'a', default => 'app.psgi');
has env => (traits => ['Getopt'], is => 'rw', isa => 'Str', cmd_aliases => 'E');

sub BUILD {
    my $self = shift;

    $ENV{CATMANDU_ENV} = $self->env if $self->env;

    if (my $app = $self->extra_argv->[1]) {
        $self->app($app);
    }
}

sub run {
    my $self = shift;
    my $catmandu = Catmandu->new;
    my $app = $self->app;
    my $eval;
    my $psgi;

    if ($app =~ m/::/) {
        $eval = $app."->as_psgi_app";
    } else {
        $psgi = $catmandu->find_psgi($app) or confess "Can't find psgi app $app";
    }

    my @argv;
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
no Any::Moose;
__PACKAGE__;

