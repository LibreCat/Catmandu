package Catmandu::Fix::trim;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);
has mode => (fix_arg => 1, default => sub { 'whitespace' });

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "if (is_string(${var})) {";
            if ($self->mode eq 'whitespace') {
                $perl .= "${var} = trim(${var});";
            }
            if ($self->mode eq 'nonword') {
                $perl .= $var.' =~ s/^\W+//;';
                $perl .= $var.' =~ s/\W+$//;';
            }
            $perl .= "}";
            $perl;
        });
    });
}

=head1 NAME

Catmandu::Fix::trim - trim leading and ending junk from the value of a field

=head1 SYNOPSIS

   # the default mode trims whitespace
   # e.g. foo => '   abc   ';
   trim('foo'); # foo => 'abc';
   trim('foo', 'whitespace'); # foo => 'abc';
   # trim non-word characters
   # e.g. foo => '   abc  / : .';
   trim('foo', 'nonword'); # foo => 'abc';

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
