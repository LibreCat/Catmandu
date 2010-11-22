use Test::More tests => 13;
use Test::Exception;
use IO::All;
use JSON;

BEGIN { use_ok 'Catmandu::Exporter::JSON'; }
require_ok 'Catmandu::Exporter::JSON';

our $list = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];
our $hash = {'a' => {'deeply' => {'nested' => $list}}};

package T::NoEach;
sub new { bless {}, shift }

package T::Each;
sub new { bless {}, shift }

sub each {
    my ($self, $sub) = @_;
    foreach my $obj (@$list) {
        $sub->($obj);
    }
}

package main;

my $file = io('$');

my $exporter = Catmandu::Exporter::JSON->new(file => $file);

isa_ok $exporter, 'Catmandu::Exporter::JSON', "isa exporter";

throws_ok { $exporter->dump("1") } qr/Can't export/, 'write string';
throws_ok { $exporter->dump(1) } qr/Can't export/, 'write integer';
throws_ok { $exporter->dump() } qr/Can't export/, 'write undef';
throws_ok { $exporter->dump(T::NoEach->new) } qr/Can't export/, 'write no each';

my $count;

$count = $exporter->dump($list);
is_deeply $list, decode_json(${$file->string_ref});
is $count, 3;

$file->truncate(0);

$count = $exporter->dump($hash);
is_deeply $hash, decode_json(${$file->string_ref});
is $count, 1;

$file->truncate(0);

$count = $exporter->dump(T::Each->new);
is_deeply $list, decode_json(${$file->string_ref});
is $count, 3;

done_testing;

