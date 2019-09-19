#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::IdGenerator::UUID';
    use_ok $pkg;
}
require_ok $pkg;

my $id_generator = $pkg->new;
isa_ok $id_generator, $pkg;
ok $id_generator->does("Catmandu::IdGenerator"),
    "An object of class '$pkg' does 'Catmandu::Id::Generator'";

my %uuids;

for my $i (0 .. 99) {
    $uuids{$id_generator->generate} = 1;
}

is scalar(keys %uuids), 100, 'uuids are unique';

done_testing;
