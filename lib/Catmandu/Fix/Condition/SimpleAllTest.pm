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

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            my $perl = $self->invert ? "if (" : "unless (";
            $perl .= $self->emit_test($var);
            $perl .= ") {";
            $perl .= "last $label;";
            $perl .= "}";
            for my $fix (@{$self->fixes}) {
                $perl .= $fixer->emit_fix($fix);
            }
            $perl;
        });
    });
}

1;
