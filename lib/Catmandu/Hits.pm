package Catmandu::Hits;

use Catmandu::Sane;

our $VERSION = '1.2016';

use Moo;
use namespace::clean;

has start          => (is => 'ro', required => 1);
has limit          => (is => 'ro', required => 1);
has total          => (is => 'ro', required => 1);
has hits           => (is => 'ro', required => 1);
has maximum_offset => (is => 'ro');

with 'Catmandu::Iterable';
with 'Catmandu::Paged';

sub size {
    scalar @{$_[0]->hits};
}

sub more {
    my $self       = $_[0];
    my $start      = $self->start;
    my $limit      = $self->limit;
    my $max_offset = $self->maximum_offset;
    return 0 if $max_offset && $start + $limit > $max_offset;
    $start + $limit < $self->total;
}

sub generator {
    my $self = $_[0];
    my $hits = $self->hits;
    my $i    = 0;
    sub {
        $hits->[$i++];
    };
}

sub to_array {
    [@{$_[0]->hits}];
}

sub count {
    scalar @{$_[0]->hits};
}

sub each {
    my ($self, $cb) = @_;
    my $hits = $self->hits;
    for my $hit (@$hits) {
        $cb->($hit);
    }
    $self->count;
}

sub first {
    $_[0]->hits->[0];
}

1;

__END__

=pod

=head1 NAME

Catmandu::Hits - Iterable object that wraps Catmandu::Store search hits

=head1 SYNOPSIS

    my $store = Catmandu::Store::Solr->new;

    my $hits  = $store->bag->search(
           query => 'dna' ,
           start => 0 ,
           limit => 100 ,
           sort  => 'title desc',
                );

    # Every hits is an iterator...
    $hits->each(sub { ... });

    printf "Found %s $hits\n" , $hits->total;

    my $start = $hits->start;
    my $limit = $hits->limit;

    my $prev = $hits->previous_page;
    my $next = $hits->next_page;

=head1 METHODS

A Catmandu::Hits object provides the following methods in addition to
methods of L<Catmandu::Iterable> and L<Catmandu::Paged>.

=head2 total

Returns the total number of hits matching the query.

=head2 start

Returns the start index for the search results.

=head2 limit

Returns the maximum number of search results returned.

=head2 more

Return true if there are more search results.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>, L<Catmandu::Store>

=cut
