package Catmandu::Fix::Condition::any_match;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use namespace::clean;

extends 'Catmandu::Fix::Condition::all_match';

sub _build_mode {'any'}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::Condition::any_match - only execute fixes if any path value matches the given regex

=head1 SYNOPSIS

   # uppercase the value of field 'foo' if at least one member of 'oogly' has the value 'doogly'
   if any_match(oogly, "doogly")
     upcase(foo) # foo => 'BAR'
   end

   # case insensitive search for 'doogly' in 'oogly' fields
   if any_match(oogly.*, "(?i)doogly")
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
