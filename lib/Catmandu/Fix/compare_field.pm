package Catmandu::Fix::compare_field;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path   => (fix_arg => 1);
has value  => (fix_arg => 1);
has string => (fix_opt => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $value = $fixer->emit_string($self->value);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            if ($self->string) {
                "${var} = ${var} cmp $value if is_value(${var});";
            }
            else {
                "${var} = ${var} <=> $value if is_value(${var});";
            }
        });
    });
}

=head1 NAME

Catmandu::Fix::compare_field - compare a field to a fixed value

=head1 SYNOPSIS

 # Returns a negative number, zero, or a positive number
 # when x is logically 'less than', 'equal to', or 'greater than'
 compare_field(x,y)

 # compare to a value. e.g. {year => '2013'}
 compare_field('year', '1990'); # {year => '1'}

 # compare to a string. e.g. {name => 'Brown'}
 compare_field('name', 'Jansen'); # {name => '-1'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;