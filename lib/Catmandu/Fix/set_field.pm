package Catmandu::Fix::set_field;

use Catmandu::Sane;
use Clone qw(clone);
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
    my $value = $fixer->emit_value($self->value);

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_set_key($var, $key, $value);
    });
}

=head1 NAME

Catmandu::Fix::set_field - add or change the value of a HASH key or ARRAY index

=head1 DESCRIPTION

Contrary to C<add_field>, this will not create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Change the value of 'foo' to 'bar 123'
   set_field('foo','bar 123');

   # Change a deeply nested key
   set_field('my.deep.nested.key','hi');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
