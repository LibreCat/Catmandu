package Catmandu::Fix::Condition::SimpleAllTest;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Condition';

requires 'emit_test';

has path => (is => 'ro', required => 1);

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    my $fixes = $self->fixes;

    my $else_fixes = $self->else_fixes;
    my $else_label;
    my $else_block = $fixer->emit_block(sub {
        $else_label = shift;
        my $perl = "";
        for my $fix (@$else_fixes) {
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
            if (@$else_fixes) {
                $perl .= "goto ${else_label};";
            } else {
                $perl .= "last ${label};";
            }
            $perl .= "}";
            $perl;
        });
    });

    $perl .= "if (${has_match_var}) {";
    for my $fix (@$fixes) {
        $perl .= $fixer->emit_fix($fix);
    }
    $perl .= "last ${label};";
    $perl .= "}";

    if (@$else_fixes) {
        $perl .= $else_block;
    }

    $perl;
}

1;
