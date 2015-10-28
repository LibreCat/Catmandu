package Catmandu::Store::Hash;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::Hash::Bag;
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

=head2 new([init_data => [...] ])

Create a new Catmandu::Store::Hash. Optionally provide as init_data an array ref of data:

    my $store = Catmandu->store('Hash', init_data => [ 
           { _id => 1, data => foo } ,
           { _id => 2, data => bar }
    ]);

    # or in a catmandu.yml configuration file:
    
    ---
    store:
       hash:
         package: Hash
         options:
            init_data:
               - _id: 1
                 data: foo
               - _id: 2
                 data: bar

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
