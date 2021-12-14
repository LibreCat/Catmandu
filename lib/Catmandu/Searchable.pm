package Catmandu::Searchable;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Catmandu::Util qw(is_natural is_positive);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

requires 'search';
requires 'searcher';
requires 'delete_by_query';

has default_limit  => (is => 'ro', builder => 'default_default_limit');
has maximum_limit  => (is => 'ro', builder => 'default_maximum_limit');
has maximum_offset => (is => 'ro');

sub default_default_limit {10}
sub default_maximum_limit {1000}

sub normalize_query {$_[1]}

sub normalize_sort {$_[1]}

my $AROUND_SEARCH = sub {
    my ($orig, $self, %args) = @_;
    $args{limit} = $self->default_limit unless is_natural($args{limit});
    $args{start} = 0                    unless is_natural($args{start});
    $args{start} += 0;
    $args{limit} += 0;
    if ($args{limit} > $self->maximum_limit) {
        $args{limit} = $self->maximum_limit;
    }
    if (is_positive(my $page = delete $args{page})) {
        $args{start} = ($page - 1) * $args{limit};
    }

    $args{query} = $self->normalize_query($args{query});
    $args{sort}  = $self->normalize_sort($args{sort});

    defined $args{$_} || delete $args{$_} for keys %args;

    $self->log->debugf("called with params %s", [%args]);

    # TODO apply maximum offset more cleanly
    if (my $max_offset = $self->maximum_offset) {
        my $start = $args{start};
        my $limit = $args{limit};
        if ($start + $limit > $max_offset) {
            $limit = ($max_offset - $start) + 1;
            $limit = 0 if $limit < 0;
        }
        my $hits = $orig->($self, %args, limit => $limit);
        $hits->{limit}          = $args{limit};
        $hits->{maximum_offset} = $max_offset;
        return $hits;
    }

    $orig->($self, %args);
};

around search   => $AROUND_SEARCH;
around searcher => $AROUND_SEARCH;

around delete_by_query => sub {
    my ($orig, $self, %args) = @_;

    $args{query} = $self->normalize_query($args{query});

    $self->log->debugf("called with params %s", [%args]);
    $orig->($self, %args);
    return;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Searchable - Optional role for searchable stores

=head1 SYNOPSIS

    my $store = Catmandu::Store::Solr->new();

    # Return one page of search results (page size = 1000)
    my $hits  = $store->bag->search(
           query => 'dna' ,
           start => 0 ,
           limit => 100 ,
           sort  => 'title desc',
                );

    # Return all the search results as iterator
    my $it    = $store->bag->searcher(query => 'dna');
    $it->each(sub { ...});

    $store->bag->delete_by_query(query => 'dna');

=head1 CONFIGURATION

=over

=item default_limit

The default value for C<limit>. By default this is C<10>.

=item maximum_limit

The maximum allowed value for C<limit>. By default this is C<1000>.

=item maximum_offset

The maximum allowed offset. When set no hits will be returned after hit offset
is greater than C<maximum_offset>, this to avoid deep paging problems.
Pagination values will be also be adjusted accordingly.

=back

=head1 METHODS

=head2 search(query => $query, start => $start, page => $page, limit => $num, sort => $sort)

Search the database and returns a L<Catmandu::Hits> on success. The Hits represents one
result page of at most $num results. The $query and $sort should implement the
query and sort syntax of the underlying search engine.

Optionally provide the index of the first result using the C<start> option, or the starting page using
the C<page> option. The number of records in a result page can be set using the C<limit> option. Sorting
options are being sent verbatim to the underlying search engine.

=head2 searcher(query => $query, start => $start, limit => $num, sort => $sort, cql_query => $cql)

Search the database and return a L<Catmandu::Iterable> on success. This iterator can be
used to loop over the complete result set. The $query and $sort should implement the
query and sort syntax of the underlying search engine.

Optionally provide the index of the first result using the C<start> option. The number of records in
a page can be set using the C<limit> option. Sorting options are being sent verbatim to the underlying
search engine.

=head2 delete_by_query(query => $query)

Delete items from the database that match $query

=head1 CQL support

Stores that are support the L<CQL query language|https://www.loc.gov/standards/sru/cql/> also accept the C<cql_query>
and C<sru_sortkeys> arguments. See L<Catmandu::CQLSearchable> for more information.

=head1 SEE ALSO

L<Catmandu::CQLSearchable>, L<Catmandu::Hits>, L<Catmandu::Paged>

=cut
