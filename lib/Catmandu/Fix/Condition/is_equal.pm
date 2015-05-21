package Catmandu::Fix::Condition::is_equal;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has path2   => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleCompareTest';

sub emit_test {
    my ($self, $var, $var2, $fixer) = @_;
    "${var} ~~ ${var2}";
}

=head1 NAME

Catmandu::Fix::Condition::is_equal - only execute fixes if both paths contain the same data

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if 'foo' equals the value of field 'bar'
   # foo => [1,2,3] , bar => [1,2,3]
   if is_equal(foo, bar)
     add_field(same, yes) # foo => [1,2,3] , bar => [1,2,3] , same => 'yes'
   end
   

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
