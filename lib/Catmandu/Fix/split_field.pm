package Catmandu::Fix::split_field;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has split_char => (fix_arg => 1, default => sub {qr'\s+'});

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $split_char = $fixer->emit_string($self->split_char);

    "${var} = [split ${split_char}, ${var}] if is_value(${var});";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::split_field - split a string value in a field into an ARRAY

=head1 SYNOPSIS

   # Split the 'foo' value into an array. E.g. foo => '1:2:3'
   split_field(foo, ':') # foo => [1,2,3]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
