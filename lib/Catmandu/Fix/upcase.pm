package Catmandu::Fix::upcase;

use Catmandu::Sane;

our $VERSION = '1.07';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "${var} = uc(as_utf8(${var})) if is_string(${var});";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::upcase - uppercase the value of a field

=head1 SYNOPSIS

   # Uppercase the value of 'foo'. E.g. foo => 'bar'
   upcase(foo) # foo => 'BAR'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
