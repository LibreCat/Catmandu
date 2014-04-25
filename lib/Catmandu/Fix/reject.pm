package Catmandu::Fix::reject;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

sub emit {
    my ($self, $fixer) = @_;
    $fixer->emit_reject;
}

1;

