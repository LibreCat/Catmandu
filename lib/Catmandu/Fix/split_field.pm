package Catmandu::Fix::split_field;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has path       => (is => 'ro', required => 1);
has split_char => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $split_char) = @_;
    $orig->($class, path => $path, split_char => $split_char // qr'\s+');
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $split_char = $fixer->emit_string($self->split_char);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = [split ${split_char}, ${var}] if is_value(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::split_field - split a string value in a field into an ARRAY

=head1 SYNOPSIS

   # Split the 'foo' value into an array. E.g. foo => '1:2:3'
   split_field('foo',':'); # foo => [1,2,3]

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
