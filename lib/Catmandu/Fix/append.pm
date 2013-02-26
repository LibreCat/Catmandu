package Catmandu::Fix::append;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has path  => (is => 'ro', required => 1);
has value => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, $path, $value) = @_;
    $orig->($class, path => $path, value => $value);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;
    my $value = $fixer->emit_string($self->value);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "${var} = join('', ${var}, $value) if is_value(${var});";
        });
    });
}

=head1 NAME

Catmandu::Fix::append - add a suffix to the value of a field

=head1 SYNOPSIS

   # append to a value. e.g. {name => 'joe'}
   append('name', 'y'); # {name => 'joey'}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
