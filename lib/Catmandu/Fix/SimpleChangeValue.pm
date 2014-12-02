package Catmandu::Fix::SimpleChangeValue;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Base';

requires 'path';
requires 'emit_change_value';

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $key = pop @$path;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            $self->emit_change_value($var, $fixer);
        });
    });
}

1;
