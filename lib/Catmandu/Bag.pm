package Catmandu::Bag;

use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo::Role;
use Data::UUID;

with 'Catmandu::Pluggable';
with 'Catmandu::Iterable';
with 'Catmandu::Addable';

requires 'get';
requires 'delete';
requires 'delete_all';

has store => (is => 'ro', required => 1);
has name  => (is => 'ro', required => 1);

before get => sub {
    check_string($_[1]);
};

around add => sub {
    my ($orig, $self, $data) = @_;
    check_hash_ref($data)->{_id} ||= $self->generate_id;
    $orig->($self, $data);
    $data;
};

before delete => sub {
    check_string($_[1]);
};

sub generate_id {
    Data::UUID->new->create_str;
}

sub commit { 1 }

sub get_or_add {
    my ($self, $id, $data) = @_;
    check_string($id);
    check_hash_ref($data);
    $self->get($id) || do {
        $data->{_id} = $id;
        $self->add($data);
    };
}

sub to_hash {
    my ($self) = @_;
    $self->reduce({}, sub {
        my ($hash, $data) = @_;
        $hash->{$data->{_id}} = $data;
        $hash;
    });
}

1;

=head1 NAME

Catmandu::Bag - A Catmandu::Store comparment to persist data

=head1 SYNOPSIS

    my $store = Catmandu::Store::DBI->new(data_source => 'DBI:mysql:database=test');
    
    # Use the default bag...
    my $bag = $store->bag;

    # Or a named bag...
    my $bag = $store->bag('journals');

    # Every bag is an iterator...
    $bag->each(sub { ... });
    $bag->take(10)->each(sub { ... });

    $bag->add($hash);
    $bag->add_many($iterator);
    $bag->add_many([ $hash, $hash , ...]);

    # Commit changes...
    $bag->commit;

    my $obj = $bag->get($id);
    $bag->delete($id);

    $bag->delete_all; 

=head1 METHODS

=head2 add($hash)

Add one hash to the store or updates an existing hash by using its '_id' key. Returns
the stored hash on success or undef on failure.

=head2 add_many($array)

=head2 add_many($iterator)

Add or update one or more items to the store.

=head2 get($id)

Retrieves the item with identifier $id from the store.

=head2 delete($id)

Deletes the item with identifier $id from the store.

=head2 delete_all

Deletes all items from the store.

=head2 commit

Commit changes.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Searchable>

=cut
