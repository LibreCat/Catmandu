package Catmandu::Counter;

use namespace::clean;
use Catmandu::Sane;
use Moo::Role;

has count => (is => 'rwp', default => sub { 0 });

sub inc_count {
    my $self = $_[0]; $self->_set_count($self->count + 1);
}

sub dec_count {
    my $self = $_[0]; $self->count ? $self->_set_count($self->count - 1) : 0;
}

sub reset_count {
    my $self = $_[0]; $self->_set_count(0);
}

1;
