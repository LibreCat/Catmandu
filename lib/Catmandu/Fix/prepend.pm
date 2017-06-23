package Catmandu::Fix::prepend;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $value = $fixer->emit_string($self->value);
    "${var} = join('', ${value}, ${var}) if is_value(${var});";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::prepend - add a prefix to the value of a field

=head1 SYNOPSIS

   # prepend to a value. e.g. {name => 'smith'}
   prepend(name, 'mr. ') # {name => 'mr. smith'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
