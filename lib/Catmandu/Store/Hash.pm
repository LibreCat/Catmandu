package Catmandu::Store::Hash;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Store';

package Catmandu::Store::Hash::Bag;

use Catmandu::Sane;
use Catmandu::Hits;
use Moo;
use Clone qw(clone);

with 'Catmandu::Bag';
with 'Catmandu::Searchable';

has _hash => (is => 'rw', init_arg => undef, default => sub { +{} });
has _head => (is => 'rw', init_arg => undef, clearer => '_clear_head');
has _tail => (is => 'rw', init_arg => undef, clearer => '_clear_tail');

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
    my $id = $data->{_id};
    my $node = $self->_hash->{$id};
    if ($node) {
        $node->[1] = clone($data);
    } elsif (my $tail = $self->_tail) {
        $tail->[2] = $node = [$tail, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_tail($node);
    } else {
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
    } else {
        $self->_head($node->[2]);
    }
    if ($node->[2]) {
        $node->[2][0] = $node->[0];
    } else {
        $self->_tail($node->[0]);
    }
    delete $self->_hash->{$id};
}

sub delete_all {
    $_[0]->_clear_head;
    $_[0]->_clear_tail;
    $_[0]->_hash({});
}

sub translate_sru_sortkeys {
    confess "TODO";
}

sub translate_cql_query {
    confess "TODO";
}

sub search {
    my ($self, %args) = @_;
    my $query = $args{query};

    my @candidates = ();

    use Data::Visitor::Callback;
    my $match = 0;
    my $visitor = Data::Visitor::Callback->new(
        value => sub { $match = 1 if $_[1] =~ /$query/},
    );

    $self->each(sub {
        my $item = shift;
        $visitor->visit($item);
        push(@candidates,$item) if $match;
        $match = 0;
    });

    Catmandu::Hits->new({
        limit => undef,
        start => 0,
        total => int(@candidates),
        hits  => \@candidates,
    });
}

sub searcher {
    return $_[0];
}

sub delete_by_query {
    my $self = shift;
    my $hits = $self->search(@_);

    $hits->each(sub {
        my $item = shift;
        $self->delete($item->{_id});
    });
}

1;
