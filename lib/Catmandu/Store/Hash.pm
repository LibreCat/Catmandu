package Catmandu::Store::Hash;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;

with 'Catmandu::Store';

has _hashes   => (is => 'ro' , lazy => 1, init_arg => undef, default => sub { +{} });
has init_data => (is => 'ro');

sub BUILD {
  my $self = $_[0];
  if (defined $self->init_data && is_array_ref($self->init_data) ) {
    for (@{$self->init_data}) {
      $self->bag->add($_);
    }
  }
}

package Catmandu::Store::Hash::Bag;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Hits;
use Moo;
use Clone qw(clone);

with 'Catmandu::Bag';

has _hash => (is => 'rw', lazy => 1 , init_arg => undef, builder => '_build_hash');
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
    my $self = $_[0];
    $self->_clear_head;
    $self->_clear_tail;
    $self->_hash($self->store->_hashes->{$self->name} = {});
}

1;

=head1 NAME

Catmandu::Store::Hash - An in-memory Catmandu::Store

=head1 SYNOPSIS

   use Catmandu::Store::Hash;

   my $store = Catmandu::Store::Hash->new();

   my $obj1 = $store->bag->add({ name => 'Patrick' });

   printf "obj1 stored as %s\n" , $obj1->{_id};

   # Force an id in the store
   my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

   my $obj3 = $store->bag->get('test123');

   $store->bag->delete('test123');

   $store->bag->delete_all;

   # All bags are iterators
   $store->bag->each(sub { ... });
   $store->bag->take(10)->each(sub { ... });

=head1 DESCRIPTION

A Catmandu::Store::Hash is an in-memory L<Catmandu::Store> backed by a hash
for fast retrieval combined with a doubly linked list for fast traversal.

=head1 METHODS

=head2 new()

Create a new Catmandu::Store::Hash

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
