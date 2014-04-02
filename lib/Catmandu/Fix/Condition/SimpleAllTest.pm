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

    my $otherwise_fixes = $self->otherwise_fixes;
    my $otherwise_label;
    my $otherwise_block = $fixer->emit_block(sub {
        $otherwise_label = shift;
        my $perl = "";
        for my $fix (@$otherwise_fixes) {
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
            if (@$otherwise_fixes) {
                $perl .= "goto ${otherwise_label};";
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

    if (@$otherwise_fixes) {
        $perl .= $otherwise_block;
    }

    $perl;
}

1;
