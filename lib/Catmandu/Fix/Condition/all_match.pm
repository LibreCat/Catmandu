package Catmandu::Fix::Condition::all_match;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    my $pattern = $self->pattern;
    "is_value(${var}) && ${var} =~ /${pattern}/";
}

=head1 NAME

Catmandu::Fix::Condition::all_match - only execute fixes if all path values match the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if all members of 'oogly' have the value 'doogly'
   if_all_match('oogly.*', 'doogly');
   upcase('foo'); # foo => 'BAR'
   end()

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
