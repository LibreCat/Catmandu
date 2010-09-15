package Catmandu::Search;

use Catmandu::Proxy;

proxy 'search';

__PACKAGE__->meta->make_immutable;
no Catmandu::Proxy;
no Mouse;

1;

__END__

=head1 NAME

 Catmandu::Search - A connection to a full-text search engine of bibliographic data structures.

=head1 SYNOPSIS

 $searcher = Catmandu::Searcher->new('SOLR', host => ..., port => ...);

 $results = $searcher->search("dna OR rna" ,
                                 start => 0 ,
                                 counts => 10 ,
                                 sort);

 printf "%d results\n" , $results->{info}->{hits};

 foreach my $res (@{$results->{data}}) {
    printf "%s %s\n" , $res->{id} , $res->{title};
 }

 $store = Catmandu::Store->new('CouchDB', host => ..., port => ...);
 
 # The results get now enriched with the document document from the store
 $results = $searcher->search("dna OR rna"
                               start => 10.
                               reify => $store);

 foreach my $res (@{$results->{data}}) {
    printf "%s %s\n" , $res->{id} , $res->{author}->{lastName};
 }

 $store->done();

 $searcher->done();

=head1 METHODS

=over 4

=item new($diver_pkg,@args) 

Constructs a new indexer. Passes @args to the driver instance.
C<$driver_pkg> is assumed to live in the Catmandu::Search
namespace unless a full package name is given. 

=item search($query,%args)

Executes a query in the full-text index retuning a HASH ref of results. This HASH
is keyed by 'info' (result metadata) and 'data' an ARRAY ref to result documents.
The arguments contain 'start', 'count' , 'sort' , 'filter' and 'reify' which is 
a reference to a Catmandu::Store instance to lookup bibliographical records for
every search result.

=item done()

Explicitly teardown the driver. This method is called at 
C<DESTROY> time. Returns 1 or 0.

=back

=head1 AUTHORS

see AUTHORS.txt in the root of this program

=head1 LICENSE

see LICENSE.txt in the root of this program

=cut
