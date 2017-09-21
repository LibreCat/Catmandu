package Catmandu::Store::Multi;

use Catmandu::Sane;

our $VERSION = '1.0604';

use Catmandu::Util qw(:is);
use Hash::Util::FieldHash qw(fieldhash);
use Catmandu::Store::Multi::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::Store';
with 'Catmandu::Droppable';

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
    for my $store (@{$self->stores}) {
        $store->drop;
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Multi - A store that adds data to multiple stores

=head1 SYNOPSIS

    # On the Command line

    # Configure the Multi store with a catmandu.yml file
    $ cat catmandu.yml
    ---
    store:
      metadata1:
       package: DBI
       options:
          data_source: "DBI:mysql:database=catmandu"
      metadata2:
       package: ElasticSearch
       options:
           client: '1_0::Direct'
           index_name: catmandu
      multi:
       package: Multi
       options:
           stores:
               - metadata1
               - metadata2
    ...

    # Add a YAML record to the multi store
    $ catmandu import YAML to multi < data.yml

    # Extract all the records from the multi store as YAML
    $ catmandu export multi to YAML > data.yml

    # In Perl
    use Catmandu;

    my $store = Catmandu->store('Multi' , stores [
        Catmandu->store('DBI', data_source => 'DBI:mysql:database=catmandu') ,
        Catmandu->store('ElasticSearch', client => '1_0::Direct', index_name => 'catmandu') ,
    ]);

    $store->bag->each(sub {
        my $item = shift;

        printf "%s\n" , $item->{_id};
    });

    $store->bag->add({ _id => 1234 , foo => 'bar' , test => [qw(1 2 3 4)]});

    my $item = $store->bag->get('1234');

    $store->bag->delete('1234');

=head1 DESCRIPTION

The L<Catmandu::Store::Multi> is a combination of many L<Catmandu::Store>-s
as one access point. The Multi store inherits all the methods
from L<Catmandu::Store>.

By default, the Multi store tries to update records in all configured backend
stores. Importing, exporting, delete and drop will be executed against
all backend stores when possible.

=head1 METHODS

=head2 new(stores => [...])

Create a new Catmandu::Store::Multi.The C<store> configuration parameter
contains an array of references to L<Catmandu::Store>-s based on their name in
a configuration file or instances.

=head1 INHERITED METHODS

This Catmandu::Store implements:

=over 3

=item L<Catmandu::Store>

=item L<Catmandu::Droppable>

=back

Each Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::Droppable>

=back

=head1 SEE ALSO

L<Catmandu::Store::File::Multi> ,
L<Catmandu::Plugin::SideCar>

=cut
