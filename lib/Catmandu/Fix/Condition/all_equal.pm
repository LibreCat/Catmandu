package Catmandu::Fix::Condition::all_equal;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    my $value = $self->value;
    "is_value(${var}) && ${var} eq '$value'";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::all_equal - Execute fixes when all path values equal a string value

=head1 DESCRIPTION

This fix is meant as an simple alternative to L<Catmandu::Fix::Condition::all_match>.
No regular expressions are involved. String are compared using the regular
operator 'eq'.

=head1 SYNOPSIS

   # all_equal(X,Y) is true when value of X == 'Y'
   if all_equal('year','2018')
    add_field('my.funny.title','true')
   end

   # all_equal(X,Y) is false when value of X == 'Ya'

=head1 SEE ALSO

L<Catmandu::Fix> , L<Catmandu::Fix::Condition::any_equal>

=cut
