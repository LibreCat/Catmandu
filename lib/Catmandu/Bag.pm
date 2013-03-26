package Catmandu::Bag;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:check);
use Moo::Role;
use Data::UUID;

with 'MooX::Log::Any';
with 'Catmandu::Pluggable'; # TODO
with 'Catmandu::Iterable';
with 'Catmandu::Addable';

requires 'get';
requires 'delete';
requires 'delete_all';

has store => (is => 'ro'); # TODO
has name  => (is => 'ro'); # TODO

before get => sub {
    check_value($_[1]);
};

before add => sub {
    my ($self, $data) = @_;
    check_hash_ref($data);
    check_value($data->{_id} //= $self->generate_id($data));
};

before delete => sub {
    check_value($_[1]);
};

sub generate_id {
    Data::UUID->new->create_str;
}

sub get_or_add {
    my ($self, $id, $data) = @_;
    check_value($id);
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

    my $store = Catmandu::Store::DBI->new(
            data_source => 'DBI:mysql:database=test',
            bags => { data => { fixes => [ ... ] } },
            bag_class => Catmandu::Bag->with_plugins('Datestamps')
            );
    
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

=head2 new(fixes => [...])

Create a new Bag with optionally an array of fixes for each item.

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

=head2 log

Return the current logger.

=head1 CLASS METHODS

=head2 with_plugins($plugin)

=head2 with_plugins(\@plugins)

Plugins are a kind of fixes that should be available for each bag. E.g. the Datestamps plugin will 
automatically store into each bag item the fields 'date_updated' and 'date_created'. The with_plugins
accept one or an array of plugin classnames and returns a subclass of the Bag with the plugin 
methods implemented.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Searchable>, L<Catmandu::Fix>, L<Catmandu::Pluggable>

=cut
