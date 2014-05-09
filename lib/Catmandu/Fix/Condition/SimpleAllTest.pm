package Catmandu::Fix::Condition::SimpleAllTest;

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
        my $perl = "";
        for my $fix (@$fail_fixes) {
            $perl .= $fixer->emit_fix($fix);
        }
        $perl;
    });

    my $has_match_var = $fixer->generate_var;

    my $perl = $fixer->emit_declare_vars($has_match_var, '0');

    $perl .= $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "${has_match_var} ||= 1;";
            $perl .= "unless (" . $self->emit_test($var) . ") {";
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
    for my $fix (@$pass_fixes) {
        $perl .= $fixer->emit_fix($fix);
    }
    $perl .= "last ${label};";
    $perl .= "}";

    if (@$fail_fixes) {
        $perl .= $fail_block;
    }

    $perl;
}

1;
