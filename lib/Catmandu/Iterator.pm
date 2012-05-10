package Catmandu::Iterator;

use Catmandu::Sane;
use Role::Tiny::With;

with 'Catmandu::Iterable';

sub generator { goto &{$_[0]} }

sub new {
    bless $_[1], $_[0];
}

1;
