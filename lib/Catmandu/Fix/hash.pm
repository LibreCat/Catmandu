package Catmandu::Fix::hash;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_array_ref(${var})) {" .
        "${var} = {\@{${var}}};" .
    "}";
}

=head1 NAME

Catmandu::Fix::hash - creates a hash out of an array

=head1 SYNOPSIS

   # tags => ['name', 'Peter', 'age', 12]
   hash(tags)
   # tags => {name => 'Peter', age => 12}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
