use Test::Exception;
use Test::Moose;
use Test::More;

BEGIN {
    $ENV{CATMANDU_TEST_SOLR} ?
        plan( tests => 19 ) :
        plan( skip_all => "enable tests with env CATMANDU_TEST_SOLR" );
}

BEGIN { use_ok 'Catmandu::Index::Solr'; }
require_ok 'Catmandu::Index::Solr';

my $url = 'http://localhost:8983/solr';

my $index = Catmandu::Index::Solr->new(url => $url, id_field => 'id');
note "index url is $url";

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

