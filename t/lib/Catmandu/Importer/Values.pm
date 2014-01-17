package Catmandu::Importer::Values;

use namespace::clean;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

has values => (is => 'ro', default => sub { '' });

sub generator {
    my ($self) = @_;
    sub {
        state $values = [ split /;/, $self->values ];
        return @$values ? { value => shift(@$values) } : undef;
    };
}

1;
