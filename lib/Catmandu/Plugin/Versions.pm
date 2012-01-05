package Catmandu::Plugin::Versions; # TODO

use Catmandu::Sane;
use Role::Tiny;

has versions_bag => (is => 'ro', lazy => 1, builder => '_build_versions_bag');

sub _build_versions_bag {
    my $self = $_[0];
    $self->store->bag($self->name . '_versions');
}

around add => sub {
    my ($orig, $self, $data) = @_;
    $orig->($self, $data);
    $data;
};

1;
