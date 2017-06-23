package Catmandu::Fix::Condition::any_equal;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAnyTest';

sub emit_test {
    my ($self, $var) = @_;
    my $value = $self->value;
    "is_value(${var}) && ${var} eq '$value'";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::any_equal - Execute fixes when at least one of the path values equal a string value

=head1 DESCRIPTION

This fix is meant as an simple alternative to L<Catmandu::Fix::Condition::any_match>.
No regular expressions are involved. String are compared using the regular
operator 'eq'.

=head1 SYNOPSIS

   # any_equal(X,Y) is true when at least one value of the array X equals 'Y'
   if any_equal('years.*','2018')
    add_field('my.funny.title','true')
   end

   # any_equal(X,Y) is false when none of the values of X equal 'Y'

=head1 SEE ALSO

L<Catmandu::Fix> , L<Catmandu::Fix::Condition::all_equal>

=cut
