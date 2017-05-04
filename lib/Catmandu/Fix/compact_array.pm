package Catmandu::Fix::compact_array;

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
                        . "${var} = [ grep { defined \$_ } \@{${var}} ];"
                        . "}";
                }
            );
        }
    );

}

=head1 NAME

Catmandu::Fix::compact_array - clear invalid values from array

=head1 SYNOPSIS

   #array => [undef,"hello",undef,"world"]
   #result => ['Hello','world']

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
