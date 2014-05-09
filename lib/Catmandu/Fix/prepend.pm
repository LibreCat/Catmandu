package Catmandu::Fix::prepend;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $value = $fixer->emit_string($self->value);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = join('', $value, ${var}) if is_value(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::prepend - add a prefix to the value of a field

=head1 SYNOPSIS

   # prepend to a value. e.g. {name => 'smith'}
   prepend('name', 'mr. '); # {name => 'mr. smith'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
