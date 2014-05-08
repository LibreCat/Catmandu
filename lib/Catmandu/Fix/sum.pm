package Catmandu::Fix::sum;

use Catmandu::Sane;
use List::Util ();
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
            "if (is_array_ref(${var})) {" .
                "${var} = List::Util::sum(\@{${var}}) // 0;" .
            "}";
        });
    });
}

=head1 NAME

Catmandu::Fix::sum - replace the value of an array field with the sum of it's elements

=head1 SYNOPSIS

   # e.g. numbers => [2, 3]
   sum('numbers');
   # numbers => 5

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;

