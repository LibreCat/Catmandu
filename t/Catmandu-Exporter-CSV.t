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

my $csv = <<EOF;
a,b
moose,1
pony,2
shrimp,3
EOF

is $out,             $csv, "CSV strings ok";
is $exporter->count, 3,    "Count ok";

$data = [{b => '1'}, {'a' => 'pony', b => '2'}, {'a' => 'shrimp', b => '3'}];
$out  = "";
$exporter = $pkg->new(file => \$out);
$exporter->add_many($data);
$exporter->commit;
$csv = <<EOF;
b
1
2
3
EOF
is $out, $csv, "first record determines fields without collect";

$out      = "";
$exporter = $pkg->new(file => \$out, collect_fields => 1);
$exporter->add_many($data);
$exporter->commit;
$csv = <<EOF;
a,b
,1
pony,2
shrimp,3
EOF
is $out, $csv, "collect field names";

$out = "";
$exporter
    = $pkg->new(fields => 'a,x', columns => 'Longname,X', file => \$out);
$exporter->add({a => 'Hello', b => 'World'});
$csv = "Longname,X\nHello,\n";
is $out, $csv, "custom column names";

$out = "";
my $fixer    = Catmandu->fixer('if exists(foo) reject() end');
my $importer = Catmandu->importer('JSON', file => 't/csv_test.json');

$exporter = $pkg->new(file => \$out);
$exporter->add_many($fixer->fix($importer));
$csv = "fob\ntest\n";
is $out, $csv, "custom column names as HASH with reject fix";

# empty exports
$out      = "";
$exporter = $pkg->new(file => \$out, header => 0);
$exporter->commit;
is $out, "";
$out      = "";
$exporter = $pkg->new(file => \$out);
$exporter->commit;
is $out, "";
$out = "";

$exporter = $pkg->new(file => \$out, fields => 'a,b', sep_char => "\t");
$exporter->add({a => 'Hello', b => 'World'});
$exporter->commit;
$csv = <<EOF;
a\tb
Hello\tWorld
EOF
is $out, $csv, "Escaped whitespace literal as sep_char";

done_testing;
