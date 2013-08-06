package Catmandu::Searchable;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo::Role;

requires 'translate_sru_sortkeys';
requires 'translate_cql_query';
requires 'search';
requires 'searcher';
requires 'delete_by_query';

has default_limit => (is => 'ro', builder => 'default_default_limit');
has maximum_limit => (is => 'ro', builder => 'default_maximum_limit');

sub default_default_limit { 10 }
sub default_maximum_limit { 1000 }

sub normalize_query { $_[1] }

my $AROUND_SEARCH = sub {
    my ($orig, $self, %args) = @_;
    $args{limit} = $self->default_limit unless is_natural($args{limit});
    $args{start} = 0                    unless is_natural($args{start});
    $args{start}+=0;
    $args{limit}+=0;
    if ($args{limit} > $self->maximum_limit) {
        $args{limit} = $self->maximum_limit;
    }
    if (is_positive(my $page = delete $args{page})) {
        $args{start} = ($page - 1) * $args{limit};
    }
    if (my $sru_sortkeys = delete $args{sru_sortkeys}) {
        $args{sort} = $self->translate_sru_sortkeys($sru_sortkeys);
    }
    if (my $cql_query = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql_query);
    }
    $args{query} = $self->normalize_query($args{query});
    $orig->($self, %args);
};

around search   => $AROUND_SEARCH;
around searcher => $AROUND_SEARCH;

around delete_by_query => sub {
    my ($orig, $self, %args) = @_;
    if (my $cql = delete $args{cql_query}) {
        $args{query} = $self->translate_cql_query($cql);
    }
    $args{query} = $self->normalize_query($args{query});
    $orig->($self, %args);
    return;
};

1;

=head1 NAME

Catmandu::Searchable - Base class for all searchable Catmandu classes

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

=head1 METHODS

=head2 search(query => $query, start => $start, limit => $num, sort => $sort, cql_query => $cql)

Search the database and returns a L<Catmandu::Hits> on success. The Hits represents one
result page of at most $num results. The $query and $sort should implement the
query and sort syntax of the underlying search engine. If the CQL language is supported
by the Store, then optionally a $cql_query search can be excuted on the Searchable.

=head2 searcher(query => $query, start => $start, limit => $num, sort => $sort, cql_query => $cql)

Search the database and return a L<Catmandu::Iterable> on success. This iterator can be
used to loop over the complete result set. The $query and $sort should implement the
query and sort syntax of the underlying search engine. If the CQL language is supported
by the Store, then optionally a $cql_query search can be excuted on the Searchable.

=head2 delete_by_query(query => $query)

Delete items from the database that match $query

=head1 SEE ALSO

L<Catmandu::Hits>

=cut
