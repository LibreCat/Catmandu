package Catmandu::Fix::uniq;

use Catmandu::Sane;

our $VERSION = '1.0601';

use List::MoreUtils ();
use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    "if (is_array_ref(${var})) {"
        . "no warnings 'uninitialized';"
        . "${var} = [List::MoreUtils::uniq(\@{${var}})];" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::uniq - strip duplicate values from an array

=head1 SYNOPSIS

   # {tags => ["foo", "bar", "bar", "foo"]}
   uniq(tags)
   # {tags => ["foo", "bar"]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
