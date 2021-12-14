use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::Mock';
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

$exporter->add($_) for @$data;
$exporter->commit;

is $out,             '', "Null is empty ok";
is $exporter->count, 3,  "Count ok";

is_deeply $exporter->as_arrayref,
    [
    {'a' => 'moose',  b => '1'},
    {'a' => 'pony',   b => '2'},
    {'a' => 'shrimp', b => '3'}
    ],
    'as_arrayref';

done_testing;
