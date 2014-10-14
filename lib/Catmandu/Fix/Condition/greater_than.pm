package Catmandu::Fix::Condition::greater_than;

=head1 NAME

Catmandu::Fix::Condition::greater_than - Excute fixes when a field is greater than a value

=head1 SYNOPSIS

   # greater_than(X,Y) is true when X > Y
   if greater_than('year','2018')
    add_field('my.funny.title','true')
   end

   # greater_than on arrays checks if all values are X > Y
   if greater_than('years.*','2018')
     add_field('my.funny.title','true')
   end

=head1 SEE ALSO

L<Catmandu::Fix::Condition::less_than>

=cut

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has value   => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    my $value = $self->value;
    "is_value(${var}) && ${var} > $value";
}

1;