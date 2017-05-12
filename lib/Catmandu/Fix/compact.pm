package Catmandu::Fix::compact;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key  = pop @$path;

    $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $var = shift;

                    "if (is_array_ref(${var})) {"
                        . "${var} = [grep defined, \@{${var}}];" . "}";
                }
            );
        }
    );

}

=head1 NAME

Catmandu::Fix::compact - remove undefined values from an array

=head1 SYNOPSIS

   # list => [undef,"hello",undef,"world"]
   compact(list)
   # list => ["Hello","world"]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
