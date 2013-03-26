package Catmandu::Iterator;

use namespace::clean;
use Catmandu::Sane;
use Role::Tiny::With;

with 'Catmandu::Iterable';

sub new {
    bless $_[1], $_[0];
}

sub generator {
    goto &{$_[0]};
}

1;
