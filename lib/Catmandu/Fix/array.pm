package Catmandu::Fix::array;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_hash_ref(${var})) {" .
        "${var} = [\%{${var}}];" .
    "}";
}

=head1 NAME

Catmandu::Fix::array - creates an array out of a hash

=head1 SYNOPSIS

   # tags => {name => 'Peter', age => 12}
   array(tags)
   # tags => ['name', 'Peter', 'age', 12]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

