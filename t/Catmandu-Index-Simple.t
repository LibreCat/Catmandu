use File::Temp;
use Test::Exception;
use Test::Moose;
use Test::More tests => 19;

BEGIN { use_ok 'Catmandu::Index::Simple'; }
require_ok 'Catmandu::Index::Simple';

my $dir = File::Temp->newdir;
my $idx = Catmandu::Index::Simple->new(path => $dir->dirname, fields => ['title']);
note "index path is $dir";

 isa_ok $idx, Catmandu::Index::Simple;
does_ok $idx, Catmandu::Index;

$obj1 = {_id => "001", title => "the third man"};
$obj2 = {_id => "002", title => "the tenth man"};

my $hits;
my $total_hits;

is_deeply $idx->save($obj1), $obj1;

$idx->save($obj2);

throws_ok { $idx->save({unknown => "field"}) } qr/Unknown field name/;

($hits, $total_hits) = $idx->find("man");
is scalar @$hits, 2;
is $total_hits, 2;
($hits, $total_hits) = $idx->find("third");
is scalar @$hits, 1;
is $total_hits, 1;
($hits, $total_hits) = $idx->find("tenth");
is scalar @$hits, 1;
is $total_hits, 1;
($hits, $total_hits) = $idx->find("third OR tenth");
is scalar @$hits, 2;
is $total_hits, 2;
($hits, $total_hits) = $idx->find("third AND tenth");
is scalar @$hits, 0;
is $total_hits, 0;

($hits, $total_hits) = $idx->find("_id : 001");
is scalar @$hits, 1;
is $total_hits, 1;

throws_ok { $idx->delete({missing => '_id'}) } qr/Missing _id/;

done_testing;

