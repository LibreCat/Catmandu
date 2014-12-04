package Catmandu::Fix::count;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_array_ref(${var})) {" .
        "${var} = scalar \@{${var}};" .
    "} elsif (is_hash_ref(${var})) {" .
        "${var} = scalar keys \%{${var}};" .
    "}";
}

=head1 NAME

Catmandu::Fix::count - replace the value of an array or hash field with it's count

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar"]
   count(tags) # tags => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
