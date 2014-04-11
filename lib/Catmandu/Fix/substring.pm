package Catmandu::Fix::substring;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);
has args => (fix_arg => 'collect');

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $args = $self->args;
    my $str_args = @$args > 1 ? join(", ", @$args[0, 1]) : $args->[0];

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            if (@$args < 3) {
                return "eval { ${var} = substr(as_utf8(${var}), ${str_args}) } if is_value(${var});";
            }
            my $replace = $fixer->emit_string($args->[2]);
            "if (is_value(${var})) {"
                ."utf8::upgrade(${var});"
                ."eval { substr(${var}, ${str_args}) = ${replace} };"
                ."}";
        });
    });
}

=head1 NAME

Catmandu::Fix::substring - extract a substring out of the value of a field

=head1 SYNOPSIS

   # Extract a substring out of the value of a field
   substring('initials',0,1);

=head1 SEE ALSO

L<Catmandu::Fix>, substr

=cut

1;
