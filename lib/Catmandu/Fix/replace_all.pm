package Catmandu::Fix::replace_all;

use Catmandu::Sane;

our $VERSION = '1.06';

use Moo;
use namespace::clean;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has search  => (fix_arg => 1);
has replace => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;

    "if (is_value(${var})) {"
        . "utf8::upgrade(${var});"
        . "${var} =~ "
        . $fixer->emit_substitution($self->search, $self->replace) . "g;"
        . "}";
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::replace_all - search and replace using regex expressions

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   # {author => "tom jones"}
   replace_all(author, '([^ ]+) ([^ ]+)', '$2, $1')
   # {author => "jones, tom"}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
