package Catmandu::Fix::append;

use Catmandu::Sane;

our $VERSION = '1.0302';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $value = $fixer->emit_string($self->value);
    "${var} = join('', ${var}, $value) if is_value(${var});";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::append - add a suffix to the value of a field

=head1 SYNOPSIS

   # append to a value. e.g. {name => 'joe'}
   append(name, y) # {name => 'joey'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
