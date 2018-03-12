package Catmandu::Fix::search_in_store;

use Catmandu::Sane;
use Catmandu::Util::Path qw(as_path);
use Catmandu;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

#options/arguments
has path       => (fix_arg => 1);
has store_name => (fix_opt => 1, init_arg => 'store');
has bag_name   => (fix_opt => 1, init_arg => 'bag');
has limit      => (fix_opt => 1, init_arg => undef, default => sub {20});
has start      => (fix_opt => 1, init_arg => undef, default => sub {0});
has sort       => (fix_opt => 1, init_arg => undef, default => sub {''});
has store_args => (fix_opt => 'collect');

#internal
has store => (is => 'lazy', init_arg => undef, builder => '_build_store');
has bag   => (is => 'lazy', init_arg => undef, builder => '_build_bag');

sub _build_store {
    my $self = $_[0];
    Catmandu->store($self->store_name, %{$self->store_args});
}

sub _build_bag {
    my ($self) = @_;
    defined $self->bag_name
        ? $self->store->bag($self->bag_name)
        : $self->store->bag;
}

sub _build_fixer {
    my ($self) = @_;
    my $bag    = $self->bag;
    my $limit  = $self->limit;
    my $start  = $self->start;
    my $sort   = $self->sort;
    as_path($self->path)->updater(
        sub {
            my $val  = $_[0];
            my $hits = $bag->search(
                query => $val,
                start => $start,
                limit => $limit,
                sort  => $sort
            );
            +{
                start => $start,
                limit => $limit,
                total => $hits->total,
                hits  => $hits->to_array
            };
        }
    );
}

=head1 NAME

Catmandu::Fix::search_in_store - use the value as query, and replace it by a search object

=head1 SYNTAX

search_in_store(path)

search_in_store(path,store: 'store', bag: 'bag', limit: 0, start: 0, sort: 'title desc')

=head1 RETURN VALUE

    {
        start: 0,
        limit: 0,
        hits: [],
        total: 1000
    }

cf. L<Catmandu::Hits>

=head1 PARAMETERS

=head2 path

The location in the perl hash where the query is stored.

See L<Catmandu::Fix/"PATHS"> for more information about paths.

=head2 store

The name of the store.

This store MUST be an implementation of L<Catmandu::Searchable>.

There are several ways to refer to a store:

    * by full package name ( e.g. 'Catmandu::Store::Solr' )
    * by short package name ( e.g. 'Solr' )
    * by name defined in the Catmandu configuration

See L<Catmandu/store-NAME> for more information.

Default is 'default'.

=head2 bag

Name of bag.

Default is 'data'.

=head2 limit

only return $limit number of records.

=head2 start

offset of records to return

=head2 sort

sort records before slicing them.

This parameter is store specific.

=head1 OTHER PARAMETERS

other parameters are given to the contructor of the L<Catmandu::Store>

e.g. catmandu.yml:


    store:
        catalog:
            package: "Catmandu::Store::Solr"

e.g. fix:

    search_in_store('foo.query', store:'catalog', bag: 'data', url: 'http://localhost:8983/solr/catalog')

=head1 EXAMPLES

    #search in Catmandu->store->bag, and store first 20 results in the foo.query.hits
    search_in_store('foo.query')

    #search in Catmandu->store->bag, and store first 20 results in the foo.query.hits
    search_in_store('foo.query', store:'default')

    #search in Catmandu->store->bag; limit number of results to 10
    search_in_store('foo.query', store:'default', limit: 10)

    #search in Catmandu->store->bag; limit number of result to 10, starting from 15
    search_in_store('foo.query', store:'default', limit: 10, start: 15)

    #search in Catmandu->store->bag('persons'); sort by year descending, and by title ascending
    search_in_store('foo.query', store:'default', bag:'persons', sort: 'year desc,title asc')

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

L<Catmandu::Store>

=cut

1;
