package Catmandu::IdGenerator;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo::Role;
use namespace::clean;

requires 'generate';

1;

__END__

=pod

=head1 NAME

Catmandu::IdGenerator - A base role for identifier generators

=head1 SYNOPSIS

    package MyGenerator;

    use Moo;

    with 'Catmandu::IdGenerator';

    sub generate {
       my ($self) = @_;
       return int(rand(999999)) . "-" . time;
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
