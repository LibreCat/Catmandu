package Catmandu::Fix::Condition::SimpleAnyTest;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Condition';

requires 'path';
requires 'emit_test';

sub emit {
    my ($self, $fixer, $label) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    my $perl = $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = "if (" . $self->emit_test($var) . ") {";

            $perl .= $fixer->emit_fixes($self->pass_fixes);

            $perl .= "last $label;";
            $perl .= "}";
            $perl;
        });
    });

    $perl .= $fixer->emit_fixes($self->fail_fixes);

    $perl;
}

1;
