package Catmandu::Iterator;

use Catmandu::Sane;

use Role::Tiny ();
use Role::Tiny::With;

with 'Catmandu::Iterable';

sub generator { goto &{$_[0]} }

sub new {
    my ($class, $sub) = @_;
    bless sub { $sub }, $class;
}

1;
