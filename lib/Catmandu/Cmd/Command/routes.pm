package Catmandu::Cmd::Command::routes;

use namespace::autoclean;
use Moose;
use Plack::Util;

extends qw(Catmandu::Cmd::Command);

has psgi_app => (
    traits => ['Getopt'],
    is => 'rw',
    isa => 'Str',
    cmd_flag => 'app',
    cmd_aliases => 'a',
    documentation => "A Catmandu::App. Can also be the first non-option argument.",
);

sub execute {
    my ($self, $opts, $args) = @_;

    my $app = shift @$args || $self->psgi_app;
    Plack::Util::load_class($app);
    print $app->inspect_routes;
}

__PACKAGE__->meta->make_immutable;

1;

