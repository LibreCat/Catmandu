package Catmandu::App::Env;

use Moose::Role;
use Catmandu::App::Request;

has env => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has request => (
    is => 'ro',
    isa => 'Catmandu::App::Request',
    lazy => 1,
    builder => '_build_request',
    handles => [qw(
        session
    )],
);

sub _build_request {
    Catmandu::App::Request->new($_[0]->env);
}

sub req {
    $_[0]->request;
}

no Moose::Role;
__PACKAGE__;

