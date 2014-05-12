#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::Fixes';
    use_ok $pkg;
}
require_ok $pkg;

my $importer = $pkg->new();

isa_ok $importer,$pkg;

my $count = 0;

lives_ok(sub { $count = $importer->count; },"try count");

ok($count > 0,"module must see Catmandu fix modules");

done_testing 5;
