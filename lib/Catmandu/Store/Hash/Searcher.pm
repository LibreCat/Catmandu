package Catmandu::Store::Hash::Searcher;
use Catmandu::Sane;
use Moo;

our $VERSION = "0.01";

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has total => (is => 'ro', required => 0);
has sort  => (is => 'ro', required => 0);

sub generator {

    my $self = $_[0];

    sub {
        state $start = $self->start;
        state $total = $self->total;
        state $bag = $self->bag;
        state $hits;

        if (defined $total) {
            return unless $total;
        }

        unless ( defined( $hits ) ) {

            $hits = $bag->_find_records( $self->query );
            $hits = $bag->_sort_records( $hits, $self->sort );
            $hits = $bag->_slice_records( $hits, $start, $total) if $total;

        }
        if ($total) {
            $total--;
        }
        my $hit = shift(@$hits) || return;
        $hit;
    };

}

=pod

=head1 NAME

Catmandu::Store::Hash::Searcher - Searcher implementation for the Hash store

=head1 ARGUMENTS

=head2 bag

Instance of L<Catmandu::Bag>

Required

=head2 query

See L<Catmandu::Store::Hash::Bag> for more information about the query format.

Optional

=head2 sort

See L<Catmandu::Store::Hash::Bag> for more information about the sort format.

Optional

=head2 start

Start at index $start

Optional

By default 0

=head2 total

Only return a total of $total object

By default all records

=head1 METHODS

Same as every L<Catmandu::Iterable> object.

=cut
1;
