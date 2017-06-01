package Catmandu::Store::MultiFiles;

use Catmandu::Sane;

our $VERSION = '1.0507';

use Catmandu::Util qw(:is);
use Hash::Util::FieldHash qw(fieldhash);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::FileStore';

has metadata => (
    is      => 'ro',
    coerce  => sub {
        my $store = $_[0];
        if (is_string($store)) {
            Catmandu->store($store);
        }
        else {
            $store;
        }
    }
);

has metadata_bag => (is => 'ro' , default => sub { 'data' });

has stores => (
    is       => 'ro',
    required => 1,
    default  => sub {[]},
    coerce   => sub {
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

    if ($self->metadata && $self->metadata->does('Catmandu::Droppable')) {
        $self->metadata->drop;
    }

    for my $store (@{$self->stores}) {
        $store->drop if $store->does('Catmandu::Droppable');
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MultiFiles - A store that adds files to multiple stores

=head1 SYNOPSIS

    # On the Command line

    # Configure the MultiFiles store with a catmandu.yml file
    $ cat catmandu.yml
    ---
    store:
      files1:
       package: Simple
       options:
          root: /data1/files
      files1:
       package: Simple
       options:
          root: /data1/files_copy
      metadata:
       package: ElasticSearch
       options:
           client: '1_0::Direct'
           index_name: catmandu
      multi:
       package: MultiFiles
       options:
           metadata: metadata
           metadata_bag: data
           stores:
               - files1
               - files2
    ...

    # Add a YAML record to the multi store
    $ catmandu import YAML to multi < data.yml

    # Extract all the records from the multi store as YAML
    $ catmandu export multi to YAML > data.yml

    # Add a file to the multi store with ID 7890 and stored name data.dat
    $ catmandu stream /tmp/data.dat to multi --bag 7890 --id data.dat

    # Download a file from the multi store
    $ catmandu stream multi --bag 7890 --id data.dat

    # In Perl
    use Catmandu;

    my $store = Catmandu->store('Multi' , stores [
        Catmandu->store('DBI', data_source => 'DBI:mysql:database=catmandu') ,
        Catmandu->store('ElasticSearch', client => '1_0::Direct', index_name => 'catmandu') ,
    ]);

    my $index = $store->index;

    $store->index->each(sub {
        my $item = shift;

        printf "%s\n" , $item->{_id};
    });

    $store->index->add({ _id => 1234 , foo => 'bar' , test => [qw(1 2 3 4)]});

    # The index has data about a colletion of file (like a folder)
    my $item = $store->index->get('1234');

    # The bag container contains all the files associated with the folder
    my $container = $store->bag('1234');

    $container->upload(IO::File->new("</tmp/data.dat"),"data.dat");

    $container->download(IO::File->new(">/tmp/data.dat"),"data.dat");

    # This will delete the item and the associated files
    $index->delete('1234');

=head1 DESCRIPTION

The L<Catmandu::Store::Multi> is a combination of many L<Catmandu::Store>-s
as one access point. The Multi store inherits all the methods
from L<Catmandu::Store>.

By default, the Multi store tries to update records in all configured backend
stores. Importing, exporting, delete and drop will be executed against
all backend stores when possible.

=head1 CONFIGURATION

=head2 stores ARRAY(string)

=head2 stores ARRAY(Catmandu::Store)

The C<store> configuration parameter contains an array of references to
L<Catmandu::Store>-s based on their name in a configuration file or instances.

=head2 metadata string

=head2 metadata Catmandu::Store

Optionally. A L<Catmandu::Store> can be linked to the MultiFiles store. For every
item in the MultiFiles store a record will be updated in the metadata store with the
same C<_id>.

When records are updated in the MultiFiles store with structured data, then the metadata
store is updated too. When records are deleted (or dropped) from the MultiFiles store
they will also be deleted (or dropped) from the MultiFiles store.

=head1 SEE ALSO

L<Catmandu::FileStore> ,
L<Catmandu::Store::Multi> ,
L<Catmandu::Store> ,
L<Catmandu::Bag>

=cut
