package Catmandu::Fix::join_field;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has path      => (is => 'ro', required => 1);
has join_char => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $join_char) = @_;
    $orig->($class, path => $path, join_char => $join_char // '');
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $join_char = $fixer->emit_string($self->join_char);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_array_ref(${var})) {".
                "${var} = join(${join_char}, grep { is_value(\$_) } \@{${var}});".
            "}";
        });
    });
}

=head1 NAME

Catmandu::Fix::join_field - join the ARRAY values of a field into a string

=head1 SYNOPSIS

   # Join the array values of a field into a string. E.g. foo => [1,2,3]
   join_field('foo','/'); # foo => "1/2/3"

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
