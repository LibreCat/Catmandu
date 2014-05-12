package Catmandu::Fix::copy_field;

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

    my $vals = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars($vals, '[]');

    $perl .= $fixer->emit_walk_path($fixer->var, $old_path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $old_key, sub {
            my $var = shift;
            "push(\@{${vals}}, ${var});";
        });
    });
    if (@$new_path && ($new_path->[-1] eq '$prepend' || $new_path->[-1] eq '$append')) {
        my $new_key = pop @$new_path;
        $perl .= $fixer->emit_create_path($fixer->var, $new_path, sub {
            my $var = shift;
            my $sym = $new_key eq '$prepend' ? 'unshift' : 'push';
            "if (\@{${vals}} && is_array_ref(${var} //= [])) {" .
                "${sym}(\@{${var}}, map { clone(\$_) } \@{${vals}});" .
            "}";
        });
    } else {
        $perl .= $fixer->emit_create_path($fixer->var, $new_path, sub {
            my $var = shift;
            "if (\@{${vals}}) {".
                "${var} = clone(shift(\@{${vals}}));".
            "}";
       });
    }

    $perl;
}

=head1 NAME

Catmandu::Fix::copy_field - copy the value of one field to a new field

=head1 SYNOPSIS

   # Copy the values of foo.bar into bar.foo
   copy_field('foo.bar','bar.foo');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
