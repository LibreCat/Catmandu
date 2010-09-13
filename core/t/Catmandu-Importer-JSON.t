#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use JSON;
use IO::String;

BEGIN { use_ok('Catmandu::Importer::JSON'); }
require_ok('Catmandu::Importer::JSON');

my $ref = [
    { id => 1, one => { deeply => { nested => { data => { structure => "ok" }}}}},
    { id => 2, another => { deeply => { nested => { data => { structure => "ok" }}}}},
];

my $file = IO::String->new(encode_json($ref));

my $importer = Catmandu::Importer::JSON->new(io => $file);

isa_ok $importer, 'Catmandu::Importer::JSON', 'isa importer';

my $count = $importer->each(sub {
    my $obj = shift;
    like($obj->{id}, qr/^\d+/, 'got id');
    if ($obj->{id} == 1) {
      is_deeply($obj->{one}, $ref->[0]->{one}, 'deeply one');
    }
    if ($obj->{id} == 2) {
      is_deeply($obj->{another}, $ref->[1]->{another}, 'deeply another');
    }
});

is $count, 2, 'counting 2 objects';

is $importer->done, 1 , 'is done';

