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

done_testing;
