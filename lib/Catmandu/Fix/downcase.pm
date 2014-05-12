package Catmandu::Fix::downcase;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = lc(as_utf8(${var})) if is_string(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::downcase - lowercase the value of a field

=head1 SYNOPSIS

   # Lowercase 'foo'. E.g. foo => 'BAR'
   downcase('foo'); # foo => 'bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
