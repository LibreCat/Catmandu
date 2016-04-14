package Catmandu::Store::Hash::Bag;

use Catmandu::Sane;

our $VERSION = '1.0002';

use Moo;
use Catmandu::Hits;
use Clone qw(clone);
use Catmandu::Util qw(:is);
use Catmandu::Store::Hash::Searcher;
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Droppable';
with 'Catmandu::Searchable';

has _hash => (is => 'rw', lazy => 1 , init_arg => undef, builder => '_build_hash');
has _head => (is => 'rw', init_arg => undef, clearer => '_clear_head');
has _tail => (is => 'rw', init_arg => undef, clearer => '_clear_tail');

sub _build_hash {
    my $self = $_[0];
    $self->store->_hashes->{$self->name} ||= {};
}

sub generator {
    my $self = $_[0];
    sub {
        state $node = $self->_head;
        state $data;
        $node || return;
        $data = $node->[1];
        $node = $node->[2];
        $data;
    };
}

sub get {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    clone($node->[1]);
}

sub add {
    my ($self, $data) = @_;
    my $id = $data->{_id};
    my $node = $self->_hash->{$id};
    if ($node) {
        $node->[1] = clone($data);
    } elsif (my $tail = $self->_tail) {
        $tail->[2] = $node = [$tail, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_tail($node);
    } else {
        $node = [undef, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_head($node);
        $self->_tail($node);
    }
    $data;
}

sub delete {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    if ($node->[0]) {
        $node->[0][2] = $node->[2];
    } else {
        $self->_head($node->[2]);
    }
    if ($node->[2]) {
        $node->[2][0] = $node->[0];
    } else {
        $self->_tail($node->[0]);
    }
    delete $self->_hash->{$id};
}

sub delete_all {
    my $self = $_[0];
    $self->_clear_head;
    $self->_clear_tail;
    $self->_hash($self->store->_hashes->{$self->name} = {});
}

sub drop {
    $_[0]->delete_all;
}

sub translate_sru_sortkeys {
    die("NOT SUPPORTED");
}
sub translate_cql_query {
    die("NOT SUPPORTED");
}
sub search {
    my ( $self, %args ) = @_;

    my $query = delete $args{query};
    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $sort = delete $args{sort};

    #all matches
    my $records = $self->_find_records( $query );

    #total
    my $total = scalar( @$records );

    #sort
    $records = $self->_sort_records( $records, $sort );

    #slice
    $records = $self->_slice_records( $records, $start, $limit );

    Catmandu::Hits->new({
        limit => $limit,
        start => $start,
        total => $total,
        hits  => $records
    });

}
sub _sort_records {
    my ( $self, $list, $sort ) = @_;

    return $list unless is_string($sort);

    #id asc,title desc => ["id asc","title desc"]
    $sort = [ split ',', $sort ];
    #["id asc","title desc"] => [["id","asc"],["title","desc"]]
    $sort = [ map { [ split (' ',$_ ) ]; } @$sort ];

    my $sort_func = sub {
        my $diff = 0;

        for my $s( @$sort ) {

            my($field,$order) = @$s;

            $diff = $a->{$field} cmp $b->{$field};
            $diff = -$diff if $order eq "desc";

            last if $diff != 0;

        }

        $diff;
    };

    [ sort $sort_func @$list ];
}
sub _find_records {
    my ($self,$query) = @_;

    if ( !is_string($query) && !is_regex_ref($query) ) {

        return $self->to_array();

    }

    $query = is_regex_ref($query) ? $query : qr/$query/;

    my $generator = $self->generator();

    my $set = [];

    while ( my $record = $generator->() )  {

        for my $key ( keys %$record ) {

            my $value = $record->{$key};

            if ( $value =~ $query ) {

                push @$set, $record;

            }

        }

    }

    $set;
}
sub _slice_records {

    my ( $self, $list, $start, $limit ) = @_;

    #slice in perl creates empty place with 'undef' when requesting for non existing places

    return [] if $limit <= 0;

    my $total = scalar( @$list );

    return [] if $start >= $total;

    my $end = $start + $limit - 1;
    $end = $total - 1 if $end >= $total;

    [ @$list[$start..$end] ];

}
sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::Hash::Searcher->new(%args, bag => $self);
}
sub delete_by_query {

    my ( $self, %args ) = @_;

    my $matches = $self->_find_records( $args{query} );

    for my $match ( @$matches ) {

        $self->delete( $match->{_id} );

    }

    scalar(@$matches);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::Hash::Bag - Bag implementation for the Hash store

=head1 METHODS

=head2 get($id)

retrieve record by identifier. Returns undef if not found.

=head2 add($record)

add or update record.

When updating the field _id is expected.

Otherwise a new record is created with a automatically generated _id.

=head2 delete($id)

delete by record identifier.

=head2 delete_all

delete all records from the current bag

=head2 drop()

in this implementation, an alias for the method 'delete_all'.

=head2 search( [ query => $query ], [ start => $start ], [ limit => $limit ], [ sort => $sort ] )

Searches in bag for records matching query $query. The query language is limited:

    * The records must be flat hashes

    * query is a regular expression (either stored as string, or as a RegExp object)

    * the query is compared against the values of the hash.

    * an empty query is interpreted as a "match all" query.


Sorts the matching records.

    * sorting on multiple keys
    * sorting in ascending ('asc') or descending ('desc') order
    * no numeric sorting
    * syntax: <field1> <asc|desc>,<field2> <asc|desc>

    e.g. "title asc,author desc"

Filters out a subset of the results, starting at index $start, with a maximum of $limit records

Returns an object of class L<Catmandu::Hits>.

The subset is stored in the attribute 'hits' of the L<Catmandu::Hits> object.

=head2 searcher( [ query => $query ], [ start => $start ], [ limit => $limit ], [ sort => $sort ] )

Comparable to the method 'search', but now it returns an L<Catmandu::Iterable>, which can be used
to loop over every match, instead of just returning a subset.

=head2 delete_by_query ( [ query => $query ] )

delete records matching query $query. See method 'search' for more information about $query.

=cut
