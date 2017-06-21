package Catmandu::Fix::hash;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_array_ref(${var})) {" . "${var} = {\@{${var}}};" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::hash - creates a hash out of an array

=head1 SYNOPSIS

   # tags => ['name', 'Peter', 'age', 12]
   hash(tags)
   # tags => {name => 'Peter', age => 12}

=head1 DESCRIPTION

This fix functions transforms array fields to hashes. The number of array
elements must be even and fields to be used as field values must be simple
strings. String fields and hash fields are left unchanged.

=head1 SEE ALSO

L<Catmandu::Fix::array>, L<Catmandu::Fix>

=cut
