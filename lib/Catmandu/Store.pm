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
        if (my $options = $self->bags->{$name}) {
            $options = {%$options};
            if (my $plugins = delete $options->{plugins}) {
                $pkg = $pkg->with_plugins($plugins);
            }
            return $pkg->new(%$options, store => $self, name => $name);
        }
        $pkg->new(store => $self, name => $name);
    };
}

1;
