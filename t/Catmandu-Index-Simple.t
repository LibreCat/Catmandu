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

my $fields = {};
my $dir = File::Temp->newdir;
my $idx = Catmandu::Index::Simple->new(path => $dir->dirname, fields => {});
note "index path is $dir";

 isa_ok $idx, Catmandu::Index::Simple;
does_ok $idx, Catmandu::Index;

my $objs = [
    {_id => "0"},
    {_id => "1"},
];
my $total_hits;

is $idx->save({unknown => "field"}), undef;

is $idx->save($objs->[0]), $objs->[0];

$idx->save($objs->[1]);

($objs, $total_hits) = $idx->find("_id:0");
is scalar @$objs, 0;
is $total_hits, 0;

$idx->done;

($objs, $total_hits) = $idx->find("_id:0");
is scalar @$objs, 1;
is $total_hits, 1;

($objs, $total_hits) = $idx->find("_id:1");
is scalar @$objs, 1;
is $total_hits, 1;

throws_ok { $idx->delete({missing => '_id'}) } qr/Missing _id/;
 lives_ok { $idx->delete({"_id" => "id"}) };
 lives_ok { $idx->delete("_id") };

done_testing;

