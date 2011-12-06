package Catmandu::Store;

use Catmandu::Sane;
use Moo::Role;

has bag_class => (
    is => 'ro',
    default => sub { ref($_[0]) . '::Bag' },
);

has default_bag => (
    is => 'ro',
    default => sub { 'data' },
);

has bags => (
    is => 'ro',
    default => sub { +{} },
);

sub bag {
    my ($self, $name) = @_;
    $name ||= $self->default_bag;
    $self->bags->{$name} ||= $self->bag_class->new(store => $self, name => $name);
}

1;
