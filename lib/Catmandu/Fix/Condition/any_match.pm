package Catmandu::Fix::Condition::any_match;

use Catmandu::Sane;

our $VERSION = '1.0002_01';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAnyTest';

sub emit_test {
    my ($self, $var, $parser) = @_;
    "is_value(${var}) && ${var} =~ ".$parser->emit_match($self->pattern);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::any_match - only execute fixes if any path value matches the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if field 'oogly' has the value 'doogly'
   if any_match(oogly, "doogly")
     upcase(foo) # foo => 'BAR'
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
