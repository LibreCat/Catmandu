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
    my $current_val = $fixer->generate_var;
    my $perl = "";
    $perl .= $fixer->emit_declare_vars($vals, '[]');
    $perl .= $fixer->emit_declare_vars($current_val);

    $perl .= $fixer->emit_walk_path($fixer->var, $old_path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $old_key, sub {
            my $var = shift;
            "push(\@{${vals}}, ${var});";
        });
    });

    $perl .= "while (\@{${vals}}) {" .
        "${current_val} = clone(shift(\@{${vals}}));" .
        $fixer->emit_create_path($fixer->var, $new_path, sub {
            my $var = shift;
            "${var} = ${current_val};";
        }).
    "}";

    $perl;
}

=head1 NAME

Catmandu::Fix::copy_field - copy the value of one field to a new field

=head1 SYNOPSIS

   # Copy the values of foo.bar into bar.foo
   copy_field(foo.bar, bar.foo)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
