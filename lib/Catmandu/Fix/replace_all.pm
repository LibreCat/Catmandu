package Catmandu::Fix::replace_all;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);
has search  => (fix_arg => 1);
has replace => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;
    my $search = $self->search;
    my $replace = $self->replace;

    "if (is_value(${var})) {"
        ."utf8::upgrade(${var});"
        ."${var} =~ s{$search}{$replace}g;"
        ."}";
}

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

1;
