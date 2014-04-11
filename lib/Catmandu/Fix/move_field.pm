package Catmandu::Fix::move_field;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has old_path => (fix_arg => 1);
has new_path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $old_path = $fixer->split_path($self->old_path);
    my $old_key = pop @$old_path;
    my $new_path = $fixer->split_path($self->new_path);

    $fixer->emit_walk_path($fixer->var, $old_path, sub {
        my $var = shift;
        $fixer->emit_delete_key($var, $old_key, sub {
            my $vals = shift;
            if (@$new_path && ($new_path->[-1] eq '$prepend' || $new_path->[-1] eq '$append')) {
                my $new_key = pop @$new_path;
                $fixer->emit_create_path($fixer->var, $new_path, sub {
                    my $var = shift;
                    my $sym = $new_key eq '$prepend' ? 'unshift' : 'push';
                    "if (\@{${vals}} && is_array_ref(${var} //= [])) {" .
                        "${sym}(\@{${var}}, \@{${vals}});" .
                    "}";
                });
            } else {
                $fixer->emit_create_path($fixer->var, $new_path, sub {
                    my $var = shift;
                    "if (\@{${vals}}) {".
                        "${var} = shift(\@{${vals}});".
                    "}";
               });
            }
        });
    });
}

=head1 NAME

Catmandu::Fix::move_field - move a field to another place in the data structure

=head1 SYNOPSIS

   # Move 'foo.bar' to 'bar.foo'
   move_field('foo.bar','bar.foo');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
