package Catmandu::Fix::set_array;

use Catmandu::Sane;

our $VERSION = '1.2013';

use Moo;
use Catmandu::Util::Path qw(as_path);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path   => (fix_arg => 1);
has values => (fix_arg => 'collect', default => sub {[]});

sub _build_fixer {
    my ($self) = @_;
    my $values = $self->values;
    as_path($self->path)->setter(sub {[@$values]});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::set_array - add or change the value of a HASH key or ARRAY index to an array

=head1 DESCRIPTION

Contrary to C<add_field>, this will not create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Change the value of 'foo' to an empty array
   set_array(foo)
   # Or an array with initial contents
   set_array(foo, "a", "b", "c")

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
