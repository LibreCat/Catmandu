package Catmandu::Fix::add_field;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path  => (fix_arg => 1);
has value => (fix_arg => 1, default => sub {undef});

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->creator($self->value);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::add_field - add or change the value of a HASH key or ARRAY index

=head1 DESCRIPTION

Contrary to C<set_field>, this will create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Add a new field 'foo' with value 2
   add_field(foo, 2)

   # Change the value of 'foo' to 'bar 123'
   add_field(foo, 'bar 123')

   # Create a deeply nested key
   add_field(my.deep.nested.key, hi)

   # If the second argument is omitted the field has a null value
   add_field(foo)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
