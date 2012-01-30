package Catmandu::Hits;

use Catmandu::Sane;
use Role::Tiny ();
use Role::Tiny::With;

with 'Catmandu::Iterable';

sub new {
    bless $_[1], $_[0];
}

sub total {
    $_[0]->{total};
}

sub start {
    $_[0]->{start};
}

sub limit {
    $_[0]->{limit};
}

sub size {
    scalar @{ $_[0]->{hits} };
}

sub hits {
    $_[0]->{hits};
}

sub to_array { goto &hits }

sub count { goto &size }

sub generator {
    my ($self) = @_;
    my $hits = $self->hits;
    my $i = 0;
    sub {
        $hits->[$i++];
    };
}

sub each {
    my ($self, $sub) = @_;
    my $hits = $self->hits;
    for my $hit (@$hits) {
        $sub->($hit);
    }
    $self->size;
}

1;

=head1 NAME

Catmandu::Hits - Iterable object that wraps Catmandu::Store search hits

=head1 SYNOPSIS

    my $store = Catmandu::Store::Solr->new();

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

=head1 METHODS

=head2 total

Returns the total number of hits matching the query.

=head2 start

Returns the start index for the search results.

=head2 limit

Returns the maximum number of search results returned.

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Bag>, L<Catmandu::Searchable>, L<Catmandu::Store>

=cut
