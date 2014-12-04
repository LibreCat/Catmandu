package Catmandu::Fix::downcase;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = lc(as_utf8(${var})) if is_string(${var});";
}

=head1 NAME

Catmandu::Fix::downcase - lowercase the value of a field

=head1 SYNOPSIS

   # Lowercase 'foo'. E.g. foo => 'BAR'
   downcase(foo) # foo => 'bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
