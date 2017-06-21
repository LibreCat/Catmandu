package Catmandu::Fix::reverse;

use Catmandu::Sane;

our $VERSION = '1.0601';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    "if (is_array_ref(${var})) {"
        . "${var} = [reverse(\@{${var}})];" . "}"
        . "elsif (is_string(${var})) {"
        . "${var} = scalar(reverse(${var}));" . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::reverse - reverse a string or an array

=head1 SYNOPSIS

   # {author => "tom jones"}
   reverse(author)
   # {author => "senoj mot"}

   # {numbers => [1,14,2]}
   reverse(numbers)
   # {numbers => [2,14,1]}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
