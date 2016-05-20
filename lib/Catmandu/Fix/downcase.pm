package Catmandu::Fix::downcase;

use Catmandu::Sane;

our $VERSION = '1.02';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = lc(as_utf8(${var})) if is_string(${var});";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::downcase - lowercase the value of a field

=head1 SYNOPSIS

   # Lowercase 'foo'. E.g. foo => 'BAR'
   downcase(foo) # foo => 'bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
