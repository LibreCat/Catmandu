package Catmandu::Fix::Condition;

use Catmandu::Sane;
use Moo::Role;

with 'Catmandu::Fix::Base';

has fixes => (is => 'ro', default => sub { [] });
has otherwise_fixes => (is => 'ro', default => sub { [] });
has in_otherwise_block => (is => 'rw', default => sub { 0 });

sub add_fix {
    my ($self, $fix) = @_;
    if ($self->in_otherwise_block) {
        push @{$self->otherwise_fixes}, $fix;
    } else {
        push @{$self->fixes}, $fix;
    }
}

1;
