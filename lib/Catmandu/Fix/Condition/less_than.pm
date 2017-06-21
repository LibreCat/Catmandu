package Catmandu::Fix::Condition::less_than;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    my $value = $self->value;
    "is_value(${var}) && ${var} < int('$value')";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::less_than - Excute fixes when a field is less than a value

=head1 SYNOPSIS

   # less_than(X,Y) is true when X < Y
   if less_than('year','2018')
    add_field('my.funny.title','true')
   end

   # less_than on arrays checks if all values are X < Y
   if less_than('years.*','2018')
     add_field('my.funny.title','true')
   end

=head1 SEE ALSO

L<Catmandu::Fix::Condition::greater_than>

=cut
