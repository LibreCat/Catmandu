package Catmandu::Cmd;
# ABSTRACT: Command line app runner
# VERSION
use Moose;

extends qw(MooseX::App::Cmd);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
