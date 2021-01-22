package Catmandu::Plugin::Readonly::Droppable;

use Catmandu::Sane;
use Moo:Role;

around drop => sub {
    my ($orig, $self) = @_;
    my $pkg = ref($self);
    $self->log->warn("trying to drop a readonly store");
    my $err = Catmandu::NotImplemented->new("$pkg is readonly");
    return undef, $err;
};

1;
