package Catmandu::Plugin::Readonly::Searchable;

use Catmandu::Sane;
use Moo::Role;

around delete_by_query => sub {
    my ($orig, $self) = @_;
    my $pkg = ref($self);
    $self->log->warn("trying to delete from readonly store");
    my $err = Catmandu::NotImplemented->new("$pkg is readonly");
    return undef, $err;
};

1;
