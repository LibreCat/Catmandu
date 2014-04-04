package Catmandu::Fix::Filter;

use Catmandu::Sane;
use Moo;

sub emit {
    my ($self, $fixer) = @_;
    $fixer->emit_reject;
}

1;

