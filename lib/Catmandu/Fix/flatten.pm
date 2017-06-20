package Catmandu::Fix::flatten;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_array_ref(${var})) {"
        . "${var} = [map { ref \$_ eq 'ARRAY' ? \@\$_ : \$_ } \@{${var}}] "
        . "while grep ref \$_ eq 'ARRAY', \@{${var}};" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::flatten - flatten a nested array field

=head1 SYNOPSIS

   # {deep => [1, [2, 3], 4, [5, [6, 7]]]}
   flatten(deep)
   # {deep => [1, 2, 3, 4, 5, 6, 7]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
