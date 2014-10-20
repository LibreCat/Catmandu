#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use YAML::XS ();

BEGIN { use_ok 'Catmandu::Exporter::YAML' }
require_ok 'Catmandu::Exporter::YAML';

my $data = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => 'shrimp'}];
my $file = "";

my $exporter = Catmandu::Exporter::YAML->new(file => \$file);
isa_ok $exporter, 'Catmandu::Exporter::YAML';

$exporter->add($_) for @$data;
$exporter->commit;
is_deeply $data, [ YAML::XS::Load($file) ];

is $exporter->count, 3, 'Count ok';

like $file, qr/^---(.+)\.\.\.$/sm, 'YAML doc';
is scalar @{[ split /^\.\.\./m, $file ]}, 4, 'YAML with --- and ...';

done_testing;

