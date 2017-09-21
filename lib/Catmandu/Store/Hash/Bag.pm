package Catmandu::Store::Hash::Bag;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Moo;
use Catmandu::Hits;
use Clone qw(clone);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Droppable';

has _hash =>
    (is => 'rw', lazy => 1, init_arg => undef, builder => '_build_hash');
has _head => (is => 'rw', init_arg => undef, clearer => '_clear_head');
has _tail => (is => 'rw', init_arg => undef, clearer => '_clear_tail');

sub _build_hash {
    my $self = $_[0];
    $self->store->_hashes->{$self->name} ||= {};
}

sub generator {
    my $self = $_[0];
    sub {
        state $node = $self->_head;
        state $data;
        $node || return;
        $data = $node->[1];
        $node = $node->[2];
        $data;
    };
}

sub get {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    clone($node->[1]);
}

sub add {
    my ($self, $data) = @_;
    my $id   = $data->{$self->id_key};
    my $node = $self->_hash->{$id};
    if ($node) {
        $node->[1] = clone($data);
    }
    elsif (my $tail = $self->_tail) {
        $tail->[2] = $node = [$tail, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_tail($node);
    }
    else {
        $node = [undef, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_head($node);
        $self->_tail($node);
    }
    $data;
}

sub delete {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    if ($node->[0]) {
        $node->[0][2] = $node->[2];
    }
    else {
        $self->_head($node->[2]);
    }
    if ($node->[2]) {
        $node->[2][0] = $node->[0];
    }
    else {
        $self->_tail($node->[0]);
    }
    delete $self->_hash->{$id};
}

sub delete_all {
    my $self = $_[0];
    $self->_clear_head;
    $self->_clear_tail;
    $self->_hash($self->store->_hashes->{$self->name} = {});
}

sub drop {
    $_[0]->delete_all;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Hash::Bag - Bag implementation for the Hash store

=cut
