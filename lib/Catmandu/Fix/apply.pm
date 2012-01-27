package Catmandu::Fix::apply;

use Catmandu::Sane;
use Moo;

has sub => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $sub) = @_;
    $orig->($class, sub => $sub);
};

sub fix {
    my ($self, $data) = @_;
    $self->sub->($data);
    $data;
}

=head1 NAME

Catmandu::Fix::apply - apply a Perl subroutine to the data object

=head1 SYNOPSIS

   # Create a deeply nested key
   apply(sub { (shift)->{perl}->{hacking}->{date} = localtime(time); });

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
