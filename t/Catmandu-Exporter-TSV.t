use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::TSV';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
    {'a' => 'moose',  b => '1'},
    {'a' => 'pony',   b => '2'},
    {'a' => 'shrimp', b => '3'}
];
my $out = "";

my $exporter = $pkg->new(file => \$out);
isa_ok $exporter, $pkg;

$exporter->add_many($data);
$exporter->commit;

my $tsv = <<EOF;
a\tb
moose\t1
pony\t2
shrimp\t3
EOF

is $out,             $tsv, "TSV strings ok";
is $exporter->count, 3,    "Count ok";

$data = [{b => '1'}, {'a' => 'pony', b => '2'}, {'a' => 'shrimp', b => '3'}];
$out  = "";
$exporter = $pkg->new(file => \$out);
$exporter->add_many($data);
$exporter->commit;
$tsv = <<EOF;
b
1
2
3
EOF
is $out, $tsv, "first record determines fields without collect";

$out      = "";
$exporter = $pkg->new(file => \$out, collect_fields => 1);
$exporter->add_many($data);
$exporter->commit;
$tsv = <<EOF;
a\tb
\t1
pony\t2
shrimp\t3
EOF
is $out, $tsv, "collect field names";

$out = "";
$exporter
    = $pkg->new(fields => 'a,x', columns => 'Longname,X', file => \$out);
$exporter->add({a => 'Hello', b => 'World'});
$tsv = "Longname\tX\nHello\t\n";
is $out, $tsv, "custom column names";

$out = "";
my $fixer    = Catmandu->fixer('if exists(foo) reject() end');
my $importer = Catmandu->importer('JSON', file => 't/csv_test.json');

$exporter = $pkg->new(file => \$out);
$exporter->add_many($fixer->fix($importer));
$tsv = "fob\ntest\n";
is $out, $tsv, "custom column names as HASH with reject fix";

done_testing;
