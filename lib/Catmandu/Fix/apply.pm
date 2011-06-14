package Catmandu::Fix::apply;
use Catmandu::Sane;
use Catmandu::Object;

sub _build_args {
    my ($self, $sub) = @_;
    { sub => $sub, };
}

sub fix {
    my ($self, $obj) = @_;
    $self->{sub}->($obj);
    $obj;
}

1;
