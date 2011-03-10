package Catmandu::Iterator;
use Catmandu::Class;
use parent qw(Catmandu::Iterable);

sub build_args {
    { each => $_[1] };
}

sub each {
    my ($self, $sub) = @_;
    $self->{each}->($sub);
}

1;
