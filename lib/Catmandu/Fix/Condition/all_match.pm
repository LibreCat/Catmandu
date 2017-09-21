package Catmandu::Fix::Condition::all_match;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has pattern => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var, $parser) = @_;
    "is_value(${var}) && ${var} =~ " . $parser->emit_match($self->pattern);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::all_match - only execute fixes if all path values match the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if all members of 'oogly' have the value 'doogly'
   if all_match(oogly.*, "doogly")
     upcase(foo) # foo => 'BAR'
   end

   # case insensitive search for 'doogly' in all 'oogly'
   if all_match(oogly.*, "(?i)doogly")
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
