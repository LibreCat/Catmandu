package Catmandu::Fix::Condition::is_false;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(((is_bool(${var}) || is_number(${var})) && ${var} + 0 == 0) || (is_string(${var}) && ${var} eq 'false'))";
}

=head1 NAME

Catmandu::Fix::Condition::is_false - only execute fixes if all path values are the boolean false, 0 or "false"

=head1 SYNOPSIS

   if is_false(data.*.has_error)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
