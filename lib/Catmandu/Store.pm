package Catmandu::Store;

use Catmandu::Sane;
use Moo::Role;
use Hash::Util::FieldHash ();

has bag_class => (
    is => 'ro',
    default => sub { ref($_[0]).'::Bag' },
);

has default_bag => (
    is => 'ro',
    default => sub { 'data' },
);

has bags => (
    is => 'ro',
    default => sub { +{} },
);

{
    Hash::Util::FieldHash::fieldhash my %bag_instances;

    sub bag {
        my $self = shift;
        my $name = shift || $self->default_bag;
        $bag_instances{$self}{$name} ||= do {
            my $pkg = $self->bag_class;
            if (my $options = $self->bags->{$name}) {
                $options = {%$options};
                if (my $plugins = delete $options->{plugins}) {
                    $pkg = $pkg->with_plugins($plugins);
                }
                return $pkg->new(%$options, store => $self, name => $name);
            }
            $pkg->new(store => $self, name => $name);
        };
    }
}

1;

=head1 NAME

Catmandu::Store - Namespace for packages that can make data persistent

=head1 SYNOPSIS

    use Catmandu::Store::DBI;

    my $store = Catmandu::Store::DBI->new(data_source => 'DBI:mysql:database=test');

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');
    
    $store->bag->delete_all;

    # Some stores can be searched
    my $hits = $store->bag->search(query => 'name:Patrick');

=head1 DESCRIPTION

A Catmandu::Store is a stub for Perl packages that can store data into
databases or search engines. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.
Some stores can be searched using Catmandu::Searchable methods.

=head1 METHODS

=head2 new(%store_args, bag_class => $class, bags => { $bagname => \%bag_args })

Create a new Catmandu::Store. Optionally provide the class name of a sub-class of
Catmandu::Bag. Startup parameters can be provided for each $bagname using the
'bags' parameter. E.g.

 my $store = Catmandu::Store::Hash->new(
		bags => {myBag => {plugins => ['Datestamps']}});

 # $store->bag('myBag') will now contain Datestamps
 
 my $bag_class = "Catmandu::Store::Hash::Bag"
 my $store = Catmandu::Store::Hash->new(
		bag_class => $bag_class->with_plugins('Datestamps')
	     );
 
 # All $store->bag(...)'s will now contain Datestamps

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
