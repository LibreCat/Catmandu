package Catmandu::Store;

use Catmandu::Sane;
use Moo::Role;
use Hash::Util::FieldHash qw(fieldhash);

fieldhash my %bag_instances;

has bag_class => (
    is => 'ro',
    default => sub { ref($_[0]).'::Bag' },
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
    my $self = shift;
    my $name = shift || $self->default_bag;
    $bag_instances{$self}{$name} ||= do {
        my $pkg = $self->bag_class;
        my $fix;
        if (exists $self->bags->{$name}{plugins}) {
            $pkg = $pkg->with_plugins($self->bags->{$name}{plugins});
        }
        if (exists $self->bags->{$name}{fix}) {
            $fix = $self->bags->{$name}{fix};
        }
        $pkg->new(store => $self, name => $name, fix => $fix);
    };
}

1;
