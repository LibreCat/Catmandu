package Catmandu::Fix::apply;

use Catmandu::Sane;
use Moo;

has sub => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $sub) = @_;
    $orig->($class, sub => $sub);
};

sub fix {
    my ($self, $data) = @_;
    $self->sub->($data);
    $data;
}

1;
