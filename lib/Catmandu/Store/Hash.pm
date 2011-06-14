package Catmandu::Store::Hash;
use Catmandu::Sane;
use Catmandu::Object hash => 'r';
use Catmandu::Util qw(ensure_id assert_id);
use Clone qw(clone);

sub _build {
    my ($self, $args) = @_;
    $self->{hash} = $args;
}

sub get {
    my ($self, $id) = @_;
    my $obj = $self->hash->{assert_id($id)} || return;
    clone($obj);
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

sub _add_obj {
    my ($self, $obj) = @_;
    my $id = ensure_id($obj);
    $self->hash->{$id} = clone($obj);
    $obj;
}

sub add {
    my ($self, $obj) = @_;
    if (quack $obj, 'each') {
        $obj->each(sub { $self->_add_obj($_[0]) });
    } else {
        $self->_add_obj($obj);
    }
}

sub delete {
    my ($self, $id) = @_;
    delete $self->hash->{assert_id($id)};
}

1;
