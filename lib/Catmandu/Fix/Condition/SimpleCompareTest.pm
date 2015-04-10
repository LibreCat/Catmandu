package Catmandu::Fix::Condition::SimpleCompareTest;

=head1 NAME

Catmandu::Fix::Condition::SimpleCompareTest - Base class to ease the construction of compare conditionals

=head1 SYNOPSIS

   package Catmandu::Fix::Condition::has_equal_type

   use Catmandu::Sane;
   use Moo;
   use Catmandu::Fix::Has;

   has path  => (fix_arg => 1);
   has path2 => (fix_arg => 1);

   with 'Catmandu::Fix::Condition::SimpleCompareTest';

   sub emit_test {
       my ($self, $var, $var2, $fixer) = @_;
       "is_value(${var}) && is_value(${var2}) && ref ${var} eq ref ${var2}";
   }

   1;

   # Now you can write in your fixes
   has_equal_type(my_field_1,my_field_2)  # True when my_field_1 and my_field_2 have
                                          # the same refence type (both scalas, arrays, hashes)

=head1 SEE ALSO

L<Catmandu::Fix::Condition::SimpleAllTest>,
L<Catmandu::Fix::Condition::SimpleAnyTest>

=cut

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Condition';

requires 'path';
requires 'path2';
requires 'emit_test';

sub emit {
    my ($self, $fixer, $label) = @_;
    
    my $path  = $fixer->split_path($self->path);
    my $key   = pop @$path;

    my $path2 = $fixer->split_path($self->path2);
    my $key2  = pop @$path2;

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    my $fail_label;
    my $fail_block = $fixer->emit_block(sub {
        $fail_label = shift;
        $fixer->emit_fixes($fail_fixes);
    });

    my $perl = "no if ($] >= 5.018), 'warnings' => 'experimental';";

    my $has_match_var = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars($has_match_var, '0');

    my $vals_1 = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars($vals_1, '{}');

    $perl .= $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "${has_match_var} ||= 1;";
            $perl   .= "${vals_1} = ${var};";
            $perl;
        });
    });

    my $vals_2 = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars($vals_2, '{}');

    $perl .= $fixer->emit_walk_path($fixer->var, $path2, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key2, sub {
            my $var = shift;
            my $perl = "${has_match_var} ||= 1;";
            $perl   .= "${vals_2} = ${var};";
            $perl;
        });
    });

    $perl .= "unless (" . $self->emit_test($vals_1,$vals_2, $fixer) . ") {";
    if (@$fail_fixes) {
      $perl .= "goto ${fail_label};";
    } else {
      $perl .= "last ${label};";
    }
    $perl .= "}";


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
