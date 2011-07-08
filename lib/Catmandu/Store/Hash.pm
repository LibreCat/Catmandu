package Catmandu::Store::Hash;
use Catmandu::Sane;
use parent qw(Catmandu::Store);

package Catmandu::Store::Hash::Collection;
use Catmandu::Sane;
use parent qw(Catmandu::Collection);
use Catmandu::Object hash => { default => '_build_hash' };
use Catmandu::Util qw(get_id);
use Clone qw(clone);

sub _build_hash {
    {};
}

sub each {
    my ($self, $sub) = @_;
    my $hash = $self->hash;
    my $n = 0;
    while (my ($id, $obj) = each(%$hash)) {
        $sub->(clone($obj));
        $n++;
    }
    $n;
}

sub _get {
    my ($self, $id) = @_;
    my $obj = $self->hash->{$id};
    clone($obj || return);
}

sub _add {
    my ($self, $obj) = @_;
    $self->hash->{get_id($obj)} = clone($obj);
    $obj;
}

sub _delete {
    my ($self, $id) = @_;
    delete $self->hash->{$id};
    return;
}

1;
