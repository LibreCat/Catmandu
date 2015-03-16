use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::CSV';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [{'a' => 'moose', b => '1'}, {'a' => 'pony', b => '2'}, {'a' => 'shrimp', b => '3'}];
my $out = "";

my $exporter = $pkg->new(file => \$out);
isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

my $csv = <<EOF;
a,b
moose,1
pony,2
shrimp,3
EOF

is $out, $csv, "CSV strings ok";
is $exporter->count,3, "Count ok";

$out = "";
$exporter = $pkg->new( fields => { a => 'Longname', x => 'X' }, file => \$out );
$exporter->add( { a => 'Hello', b => 'World' } );
$csv = "Longname,X\nHello,\n";
is $out, $csv, "custom column names as HASH";

done_testing;
