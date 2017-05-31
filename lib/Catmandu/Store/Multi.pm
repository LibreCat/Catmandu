package Catmandu::Store::Multi;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Util qw(:is);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::Store';

has stores => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        my $stores = $_[0];
        return [
            map {
                if (is_string($_)) {
                    Catmandu->store($_);
                }
                else {
                    $_;
                }
            } @$stores
        ];
    },
);

sub drop {
    my ($self) = @_;
    for my $store (@{$self->store->stores}) {
        $store->drop;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi - A store that adds your data to multiple stores

=head1 SYNOPSIS
    # On the Command line

    # Configure the Multis tore with a catmandu.yml file
    $ cat catmandu.yml
    ---
    store:
      files:
       package: Simple
       options:
           root: /data/test
      metadata:
       package: ElasticSearch
       options:
           client: '1_0::Direct'
           index_name: catmandu
      multi:
       package: Multi
       options:
           stores:
               - metadata
               - files
    ...

    # Add a YAML record to the multi store
    $ catmandu import YAML to multi < data.yml

    # Extract all the records from the multi store as YAML
    $ catmandu export multi to YAML > data.yml

    # Upload a binary file for a YAML record with id '1234'
    $ catmandu stream /tmp/bigfile to multi --bag 1234 --id bigfile

    # Extract a binary file from the multi store
    $ catmandu stream multi --bag 1234 --id bigfile > /tmp/bigfile

    # In Perl
    use Catmandu;

    my $store = Catmandu->store('Multi' , stores [
        Catmandu->store('Simple', root => '/data/test') ,
        Catmandu->store('ElasticSearch', client => '1_0::Direct', index_name => 'catmandu') ,
    ]);

    $store->bag->each(sub {
        my $item = shift;

        printf "%s\n" , $item->{_id};
    });

    $store->bag->add({ _id => 1234 , foo => 'bar' , test => [qw(1 2 3 4)]});

    my $item = $store->bag->get('1234');

    # Store a file into the bag associated with item '1234'
    $store->bag('1234')->upload(IO::File->new('/tmp/bigfile '), 'bigfile');

    # Download a file associated with item '1234'
    $store->bag('1234')->stream(IO::File->new("> output"), 'bigfile');

    # This will delete the item and the associated files
    $store->delete('1234');

=head1 DESCRIPTION

The L<Catmandu::Store::Multi> is a combination of many L<Catmandu::Store>-s or
L<Catmandu::FileStore>-s as one access point. The Multi store inherits all the methods
from L<Catmandu::Store> and L<Catmandu::FileStore>.

The Multi store can be used to store structured records in two or more L<Catmandu::Store>-s
(for instance a L<Catmandu::Store::DBI> and a L<Catmandu::Store::ElasticSearch>)). Or,
combinations of L<Catmandu::Store> with L<Catmandu::FileStore> can be used to store
structured and unstructured data using one access point.

By default, the Multi store tries to update records in all configured backend
stores. Importing, exporting, drop, delete and stream will be executed against
all stores when possible.

=head1 CAVECATS

When combining L<Catmandu::Store>-s with L<Catmandu::FileStore>-s in a
L<Catmandu::Store::Multi> then all record identifiers '_id' B<must> respect the
limitations of the backend FileStore. E.g. when using a L<Catmandu::Store::Simple>
this means that all _id fields should be integers with a maximum defined
by the Simple store.

=head1 SEE ALSO

L<Catmandu::Store::Multi::Bag> ,
L<Catmandu::Store> ,
L<Catmandu::Bag>
L<Catmandu::FileStore> ,
L<Catmandu::FileStore::Bag>

=cut
