package Catmandu::Cmd::Command::routes;
# VERSION
use namespace::autoclean;
use Moose;
use Catmandu::Util;

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
    Catmandu::Util::load_class($app);
    print $app->inspect_routes;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catmandu::Cmd::Command::routes - inspect an app's routes

