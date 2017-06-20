package Catmandu::Bag;

use Catmandu::Sane;

our $VERSION = '1.06';

use Catmandu::Util qw(:check is_string require_package);
use Catmandu::Bag::IdGenerator::UUID;
use Moo::Role;
use MooX::Aliases;
use namespace::clean;

with 'Catmandu::Logger';
with 'Catmandu::Pluggable';
with 'Catmandu::Iterable';
with 'Catmandu::Addable';

requires 'get';
requires 'delete';
requires 'delete_all';

has store  => (is => 'ro',   required => 1);
has name   => (is => 'ro',   required => 1);
has id_key => (is => 'lazy', alias    => 'id_field');
has id_generator => (
    is     => 'lazy',
    coerce => sub {
        if (is_string($_[0])) {
            require_package($_[0], 'Catmandu::Bag::IdGenerator')->new;
        }
        else {
            $_[0];
        }
    },
);

sub _build_id_key {
    $_[0]->store->id_key;
}

sub _build_id_generator {
    state $uuid = Catmandu::Bag::IdGenerator::UUID->new;
}

before get => sub {
    check_value($_[1]);
};

before add => sub {
    my ($self, $data) = @_;
    check_hash_ref($data);
    check_value($data->{$self->id_key} //= $self->generate_id($data));
};

before delete => sub {
    check_value($_[1]);
};

around delete_all => sub {
    my ($orig, $self) = @_;
    $orig->($self);
    return;
};

sub generate_id {
    my ($self) = @_;
    $self->id_generator->generate($self);
}

sub exists {
    my ($self, $id) = @_;
    defined $self->get($id) ? 1 : 0;
}

sub get_or_add {
    my ($self, $id, $data) = @_;
    check_value($id);
    check_hash_ref($data);
    $self->get($id) // do {
        $data->{$self->id_key} = $id;
        $self->add($data);
    };
}

sub to_hash {
    my ($self) = @_;
    $self->reduce(
        {},
        sub {
            my ($hash, $data) = @_;
            $hash->{$data->{$self->id_key}} = $data;
            $hash;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Bag - A Catmandu::Store compartment to persist data

=head1 SYNOPSIS

    my $store = Catmandu::Store::DBI->new(data_source => 'DBI:mysql:database=test');

    my $store = Catmandu::Store::DBI->new(
            data_source => 'DBI:mysql:database=test',
            bags => { journals => {
                            fix => [ ... ] ,
                            autocommit => 1 ,
                            plugins => [ ... ] ,
                            id_generator => Catmandu::IdGenerator::UUID->new ,
                      }
                    },
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

    if ($bag->exists($id)) {
        # ...
    }

    my $obj = $bag->get($id);
    $bag->delete($id);

    $bag->delete_all;

=head1 CONFIGURATION

=over

=item fix

Contains an array of fixes (or Fix files) to be applied before importing data into the bag.

=item plugins

An array of Catmandu::Pluggable to apply to the bag items.

=item autocommit

When set to a true value an commit automatically gets executed when the bag
goes out of scope.

=item id_generator

A L<Catmandu::IdGenerator> or name of an IdGenerator class.
By default L<Catmandu::IdGenerator::UUID> is used.

=item id_key

Use a custom key to hold id's in this bag. See L<Catmandu::Store> for the
default or store wide value. Also aliased as C<id_field>.

=back

=head1 METHODS

=head2 add($hash)

Add a hash to the bag or updates an existing hash by using its '_id' key. Returns
the stored hash on success or undef on failure.

=head2 add_many($array)

=head2 add_many($iterator)

Add or update one or more items to the bag.

=head2 get($id)

Retrieves the item with identifier $id from the bag.

=head2 exists($id)

Returns C<1> if the item with identifier $id exists in the bag.

=head2 get_or_add($id, $hash)

Retrieves the item with identifier $id from the store or adds C<$hash> with _id
C<$id> if it's not found.

=head2 delete($id)

Deletes the item with C<$id> from the bag.

=head2 delete_all

Clear the bag.

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
