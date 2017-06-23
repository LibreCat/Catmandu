package Catmandu::Fix::join_field;

use Catmandu::Sane;

our $VERSION = '1.0602';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has join_char => (fix_arg => 1, default => sub {''});

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $join_char = $fixer->emit_string($self->join_char);

    "if (is_array_ref(${var})) {"
        . "${var} = join(${join_char}, grep { is_value(\$_) } \@{${var}});"
        . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::join_field - join the ARRAY values of a field into a string

=head1 SYNOPSIS

   # Join the array values of a field into a string. E.g. foo => [1,2,3]
   join_field(foo, /) # foo => "1/2/3"

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
