package Catmandu::Cmd::Command;
# ABSTRACT: Base class for commands
# VERSION
use 5.010;
use Moose;
use Catmandu::Cmd::Opts;
use Catmandu;
use Path::Class;

extends qw(MooseX::App::Cmd::Command);

with qw(MooseX::Getopt::Dashes);

has home => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'H',
    documentation => "The project home directory. Defaults to the current directory.",
);

has env => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_aliases => 'E',
    default => 'development',
    documentation => "The project environment. Defaults to development.",
);

sub BUILD {
    my $self = shift;

    print $self->help_text and exit if $self->help_flag;

    if ($self->home) {
        $self->home(dir($self->home)->absolute->resolve->stringify);
    } else {
        $self->home(dir->absolute->stringify);
    }

    Catmandu->initialize(home => $self->home,
                         env  => $self->env);
    unshift @INC, Catmandu->lib;
    Catmandu->auto;
}

sub help_text {
    my $self = shift;
    $self->usage->leader_text . "\n" . $self->usage->option_text;
}

__PACKAGE__->meta->make_immutable;
no Path::Class;
no Moose;
1;

