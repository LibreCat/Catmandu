package Catmandu::Fix::clone;
use Catmandu::Sane;
use Catmandu::Object;
use Clone qw(clone);

sub fix {
    clone $_[1];
}

1;
