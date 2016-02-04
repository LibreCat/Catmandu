package Catmandu::Fix::Condition::is_true;

use Catmandu::Sane;

our $VERSION = '1.00_01';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(((is_bool(${var}) || is_number(${var})) && ${var} + 0 == 1) || (is_string(${var}) && ${var} eq 'true'))";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::is_true - only execute fixes if all path values are the boolean true, 1 or "true"

=head1 SYNOPSIS

   if is_true(data.*.has_error)
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
