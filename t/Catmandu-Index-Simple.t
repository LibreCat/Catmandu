use File::Temp;
use Test::More;
use Test::Exception;
BEGIN {
    require Any::Moose;
    if (Any::Moose::moose_is_preferred) {
        use Test::Moose;
    } else {
        use Test::Mouse;
    }
}

BEGIN { use_ok 'Catmandu::Index::Simple'; }
require_ok 'Catmandu::Index::Simple';

my $dir = File::Temp->newdir;
my $idx = Catmandu::Index::Simple->new(path => $dir->dirname);
note "index path is $dir";

 isa_ok $idx, Catmandu::Index::Simple;
does_ok $idx, Catmandu::Index;

my $objs;
my $total_hits;

$idx->save({_id => "1"});
$idx->save({_id => "2"});

($objs, $total_hits) = $idx->find("_id:1");
is scalar @$objs, 0;
is $total_hits, 0;

$idx->done;

($objs, $total_hits) = $idx->find("_id:1");
is scalar @$objs, 1;
is $total_hits, 1;

($objs, $total_hits) = $idx->find("_id:2");
is scalar @$objs, 1;
is $total_hits, 1;

throws_ok { $idx->delete({missing => '_id'}) } qr/Missing _id/;

done_testing;

