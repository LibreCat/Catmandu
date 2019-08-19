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

my $id = $id_generator->generate;

isnt $id, $id_generator->generate;

like $id,
    qr/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/,
    'id matches a UUID v4';

done_testing;
