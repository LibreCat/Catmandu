package Catmandu::Fix::array;

use Catmandu::Sane;

our $VERSION = '1.0503';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_hash_ref(${var})) {" . "${var} = [\%{${var}}];" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::array - creates an array out of a hash

=head1 SYNOPSIS

   # tags => {name => 'Peter', age => 12}
   array(tags)
   # tags => ['name', 'Peter', 'age', 12]

=head1 DESCRIPTION

This fix functions transforms hash fields to array. String fields and array
fields are left unchanged.

=head1 SEE ALSO

L<Catmandu::Fix::hash>, L<Catmandu::Fix>

=cut
