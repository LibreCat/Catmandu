package Catmandu::Fix::clone;

use Catmandu::Sane;
use Moo;
use Clone;

sub fix {
    Clone::clone($_[1]);
}

1;
