package Catmandu::Fix::set_hash;
use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_set_key($var, $key, "{}");
    });
}

=head1 NAME

Catmandu::Fix::set_hash - add or change the value of a HASH key or ARRAY index to an empty hash

=head1 DESCRIPTION

Contrary to C<add_field>, this will not create the intermediate structures
if they are missing.

=head1 SYNOPSIS

   # Change the value of 'foo' to an empty hash
   set_hash(foo)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
