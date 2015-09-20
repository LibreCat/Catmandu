#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use YAML::XS ();

BEGIN { use_ok 'Catmandu::Exporter::Text' }
require_ok 'Catmandu::Exporter::Text';

{
    my $data = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => ['shrimp','lobster']}];
    my $file = "";

    my $exporter = Catmandu::Exporter::Text->new(file => \$file, line_sep => '\n' , field_sep => ',');
    isa_ok $exporter, 'Catmandu::Exporter::Text';

    $exporter->add($_) for @$data;
    $exporter->commit;

    is $exporter->count, 3, 'Count ok';

    my $text =<<EOF;
moose
pony
shrimp,lobster
EOF

    is $file, $text, 'Text doc hash';
}

{
    my $data = [{'a' => 'moose'}, {'a' => 'pony'}, {'a' => ['shrimp','lobster']}];
    my $file = "";

    my $exporter = Catmandu::Exporter::Text->new(file => \$file, line_sep => '\n' , field_sep => ',');
    isa_ok $exporter, 'Catmandu::Exporter::Text';

    $exporter->add_many($data);
    $exporter->commit;

    is $exporter->count, 3, 'Count ok';

    my $text =<<EOF;
moose
pony
shrimp,lobster
EOF

    is $file, $text, 'Text doc array';
}

done_testing;