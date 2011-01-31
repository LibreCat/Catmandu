use Test::More tests => 8;
use Test::Moose;
use Test::Exception;
use IO::String;

BEGIN { use_ok 'Catmandu::Importer::CSV'; }
require_ok 'Catmandu::Importer::CSV';

my $objs = [
   { 'Name' => 'Patrick' , 'Age' => '39' } ,
   { 'Name' => 'Nicolas' , 'Age' => '34' } ,
];

my $csv =<<EOF;
"Name","Age"
"Patrick","39"
"Nicolas","34"
EOF

my $importer = Catmandu::Importer::CSV->new(file => IO::String->new($csv));

 isa_ok $importer, Catmandu::Importer::CSV;
does_ok $importer, Catmandu::Importer;

my $n = $importer->each(sub {
    my $obj = shift;

    like $obj->{Name}, qr/^\w+/, 'got Name';

    if ($obj->{Name} eq 'Patrick') {
      is_deeply $obj, $objs->[0], 'deeply one';
    }
    if ($obj->{id} eq 'Nicolas') {
      is_deeply $obj, $objs->[1], 'deeply another';
    }
});


is $n, 2;

done_testing;
