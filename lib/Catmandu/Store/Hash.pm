package Catmandu::Store::Hash;
use Catmandu::Sane;
use parent qw(Catmandu::Store);
use Catmandu::Object hash => 'r';
use Catmandu::Util qw(get_id);
use Clone qw(clone);

sub _build {
    my ($self, $args) = @_;
    $self->{hash} = $args;
    $self->SUPER::_build($args);
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
    my $obj = $self->hash->{$id} || return;
    clone($obj);
}

sub _add {
    my ($self, $obj) = @_;
    $self->hash->{get_id($obj)} = clone($obj);
    $obj;
}

sub _delete {
    my ($self, $id) = @_;
    delete $self->hash->{$id};
}

1;
