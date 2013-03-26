package Catmandu::Fix::Base;

use Catmandu::Sane;
use Catmandu::Fix;
use Moo::Role;

with 'MooX::Log::Any';

requires 'emit';

has fixer => (is => 'lazy', init_arg => undef);

sub _build_fixer {
    my ($self) = @_;
    Catmandu::Fix->new(fixes => [$self]);
}

sub fix {
    my ($self, $data) = @_;
    $self->fixer->fix($data);
}

1;
