package Catmandu::Searchable;

use Catmandu::Sane;

our $VERSION = '1.0605';

use Catmandu::Util qw(is_natural is_positive);
use Moo::Role;
use namespace::clean;

with 'Catmandu::Logger';

requires 'search';
requires 'searcher';
requires 'delete_by_query';

has default_limit => (is => 'ro', builder => 'default_default_limit');
has maximum_limit => (is => 'ro', builder => 'default_maximum_limit');

sub default_default_limit {10}
sub default_maximum_limit {1000}

sub normalize_query {$_[1]}

sub normalize_sort {$_[1]}

my $AROUND_SEARCH = sub {
    my ($orig, $self, %args) = @_;
    $args{limit} = $self->default_limit unless is_natural($args{limit});
    $args{start} = 0 unless is_natural($args{start});
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

=head1 SEE ALSO

L<Catmandu::Hits>, L<Catmandu::Paged>

=cut
