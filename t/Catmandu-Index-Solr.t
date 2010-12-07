use Test::Exception;
use Test::Moose;
use Test::More tests => 19;

BEGIN { use_ok 'Catmandu::Index::Solr'; }
require_ok 'Catmandu::Index::Solr';

my $path = 'http://localhost:8983/solr';

my $index = Catmandu::Index::Solr->new(path => $path, id_term => 'id');
note "index path is $path";

 isa_ok $index, Catmandu::Index::Solr;
does_ok $index, Catmandu::Index;

$obj1 = {id => "001", name => "the third man"};
$obj2 = {id => "002", name => "the tenth man"};

my $hits;
my $total_hits;

is_deeply $index->save($obj1), $obj1;
is_deeply $index->save($obj2), $obj2;

($hits, $total_hits) = $index->search("name:man");
is scalar @$hits, 2;
is $total_hits, 2;

($hits, $total_hits) = $index->search("name:third");
is scalar @$hits, 1;
is $total_hits, 1;

($hits, $total_hits) = $index->search("name:tenth");
is scalar @$hits, 1;
is $total_hits, 1;

($hits, $total_hits) = $index->search("name:third OR name:tenth");
is scalar @$hits, 2;
is $total_hits, 2;

($hits, $total_hits) = $index->search("name:third AND name:tenth");
is scalar @$hits, 0;
is $total_hits, 0;


throws_ok { $index->delete({missing => '_id'}) } qr/Missing/;

$index->delete({id => "001"});
($hits, $total_hits) = $index->search("id:001");
is $total_hits, 0;

$index->delete("002");
($hits, $total_hits) = $index->search("id:002");
is $total_hits, 0;

done_testing;
