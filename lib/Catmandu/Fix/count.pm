package Catmandu::Fix::count;

use Catmandu::Sane;

our $VERSION = '1.09';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    "if (is_array_ref(${var})) {"
        . "${var} = scalar \@{${var}};"
        . "} elsif (is_hash_ref(${var})) {"
        . "${var} = scalar keys \%{${var}};" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::count - replace the value of an array or hash field with its count

=head1 SYNOPSIS

   # e.g. tags => ["foo", "bar"]
   count(tags) # tags => 2

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
