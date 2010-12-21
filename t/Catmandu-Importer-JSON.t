use Test::More tests => 9;
use Test::Moose;
use Test::Exception;
use IO::String;
use JSON;

BEGIN { use_ok 'Catmandu::Importer::JSON'; }
require_ok 'Catmandu::Importer::JSON';

my $objs = [
    { id => 1, one     => { deeply => { nested => { data => { structure => "ok" }}}}},
    { id => 2, another => { deeply => { nested => { data => { structure => "ok" }}}}},
];

my $importer = Catmandu::Importer::JSON->new(file => IO::String->new(encode_json($objs)));

 isa_ok $importer, Catmandu::Importer::JSON;
does_ok $importer, Catmandu::Importer;

my $n = $importer->each(sub {
    my $obj = shift;

    like $obj->{id}, qr/^\d+/, 'got id';

    if ($obj->{id} == 1) {
      is_deeply $obj->{one}, $objs->[0]->{one}, 'deeply one';
    }
    if ($obj->{id} == 2) {
      is_deeply $obj->{another}, $objs->[1]->{another}, 'deeply another';
    }
});

is $n, 2;

done_testing;

