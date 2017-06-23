package Catmandu::IdGenerator::Mock;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use Catmandu::Util qw(check_natural);
use namespace::clean;

with 'Catmandu::IdGenerator';

has first_id =>
    (is => 'ro', isa => sub {check_natural($_[0])}, default => sub {0},);

has next_id =>
    (is => 'rwp', init_arg => undef, lazy => 1, builder => 'first_id',);

sub generate {
    my ($self) = @_;
    my $id = $self->next_id;
    $self->_set_next_id($id + 1);
    $id;
}

1;

__END__

=pod

=head1 NAME

Catmandu::IdGenerator::Mock - Generator of increasing identifiers

=head1 SYNOPSIS

    use Catmandu::IdGenerator::Mock;

    my $x = Catmandu::IdGenerator::Mock->new(first_id => 10);

    for (1..100) {
       printf "id: %s\n" m $x->generate;
    }

=head1 SEE ALSO

This L<Catmandu::IdGenerator> generates identifiers based on the sequence of
natural numbers.

=head1 CONFIGURATION

=over

=item first_id

First number to start from. Set to C<0> by default (zero-based numbering).

=back

=cut
