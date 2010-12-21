package Catmandu::Cmd;
# ABSTRACT: Command line app runner
# VERSION
use namespace::autoclean;
use Moose;

extends qw(MooseX::App::Cmd);

__PACKAGE__->meta->make_immutable;

1;

