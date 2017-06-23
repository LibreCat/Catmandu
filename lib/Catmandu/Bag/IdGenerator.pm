package Catmandu::Bag::IdGenerator;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo::Role;
use namespace::clean;

with 'Catmandu::IdGenerator';

1;

__END__

=pod

=head1 NAME

Catmandu::Bag::IdGenerator - A base role for bag identifier generators

=head1 SYNOPSIS

    package MyGenerator;

    use Moo;

    with 'Catmandu::Bag::IdGenerator';

    sub generate {
       my ($self, $bag) = @_;
       return $bag->name . "-" . int(ran(999999)) . "-" . time;
    }

    package main;

    my $gen = MyGenerator->new;

    for (1..100) {
       printf "id: %s\n" m $gen->generate;
    }

=head1 SEE ALSO

L<Catmandu::IdGenerator::Mock> ,
L<Catmandu::IdGenerator::UUID>

=cut

