package Catmandu::FixCondition;

use Catmandu::Sane;
use Moo::Role;

requires 'is_fixable';

has fixes  => (is => 'ro', default => sub { [] });
has invert => (is => 'rw');

sub fix {
    my ($self, $data) = @_;

    my $ok = $self->is_fixable($data);
    if ($self->invert) {
        $ok = !$ok;
    }

    if ($ok) {
        for my $fix (@{$self->fixes}) {
            $data = $fix->fix($data);
        }
    }

    $data
}

1;
