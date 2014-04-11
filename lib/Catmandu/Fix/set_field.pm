package Catmandu::Fix::set_field;

use Catmandu::Sane;
use Clone qw(clone);
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

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
