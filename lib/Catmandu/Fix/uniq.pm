package Catmandu::Fix::uniq;

use Catmandu::Sane;
use List::MoreUtils ();
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    "if (is_array_ref(${var})) {" .
        "no warnings 'undefined';" .
        "${var} = [List::MoreUtils::uniq(\@{${var}})];" .
    "}";
}

=head1 NAME

Catmandu::Fix::uniq - strip duplicate values from an array

=head1 SYNOPSIS

   # {tags => ["foo", "bar", "bar", "foo"]}
   uniq(tags)
   # {tags => ["foo", "bar"]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
