package Catmandu::MultiIterator;

use Catmandu::Sane;
use Moo;
use namespace::clean;

with 'Catmandu::MultiIterable';

sub BUILDARGS {
    my ($class, @iterators) = @_;
    return {iterators => [ @importers ]};
}

1;

