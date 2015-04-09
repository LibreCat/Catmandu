package Catmandu::Fix::Condition::SimpleAllTest;

=head1 NAME

Catmandu::Fix::Condition::SimpleAllTest - Base class to ease the construction of all match conditionals

=head1 SYNOPSIS

   package Catmandu::Fix::Condition::is_even

   use Catmandu::Sane;
   use Moo;
   use Catmandu::Fix::Has;

   has path => (fix_arg => 1);

   with 'Catmandu::Fix::Condition::SimpleAllTest';

   sub emit_test {
       my ($self, $var) = @_;
       "is_value(${var}) && ${var} % 2 == 0";
   }

   1;

   # Now you can write in your fixes
   is_even('my_field')    # True when my_field is 0,2,4,6,...
   is_even('my_field.*')  # True when all my_field's are 0,2,4,6,...

=head1 DESCRIPTION

The is a base class to ease the construction of Catmandu::Fix::Conditional-s. An 'all' test matches
when all node on a path match a condition. E.g.

   all_match('title','abc')    # true when the title field contains 'abc'

   all_match('title.*','abc')  # true when all title fields contain 'abc'

=head1 SEE ALSO

L<Catmandu::Fix::Condition::all_match>,
L<Catmandu::Fix::Condition::greater_than>,
L<Catmandu::Fix::Condition::less_than>

=cut

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Condition';

requires 'path';
requires 'emit_test';

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    my $fail_label;
    my $fail_block = $fixer->emit_block(sub {
        $fail_label = shift;

        $fixer->emit_fixes($fail_fixes);
    });

    my $has_match_var = $fixer->generate_var;

    my $perl = $fixer->emit_declare_vars($has_match_var, '0');

    $perl .= $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "${has_match_var} ||= 1;";
            $perl .= "unless (" . $self->emit_test($var, $fixer) . ") {";
            if (@$fail_fixes) {
                $perl .= "goto ${fail_label};";
            } else {
                $perl .= "last ${label};";
            }
            $perl .= "}";
            $perl;
        });
    });

    $perl .= "if (${has_match_var}) {";

    $perl .= $fixer->emit_fixes($pass_fixes);

    $perl .= "last ${label};";
    $perl .= "}";

    if (@$fail_fixes) {
        $perl .= $fail_block;
    }

    $perl;
}

1;
