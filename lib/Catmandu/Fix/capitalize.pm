package Catmandu::Fix::capitalize;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = ucfirst(lc(as_utf8(${var}))) if is_string(${var});";
}

=head1 NAME

Catmandu::Fix::capitalize - capitalize the value of a key

=head1 SYNOPSIS

   # Capitalize the value of foo. E.g. foo => 'bar'
   capitalize(foo)  # foo => 'Bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
