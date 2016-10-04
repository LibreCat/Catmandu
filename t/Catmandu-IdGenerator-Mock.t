#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::IdGenerator::Mock';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $expected     = [0 .. 10];
    my $generated    = [];
    my $id_generator = $pkg->new;
    isa_ok $id_generator, $pkg;
    ok $id_generator->does("Catmandu::IdGenerator"),
        "an object of class '$pkg' does 'Catmandu::IdGenerator'";
    push @$generated, map {$id_generator->generate} @$expected;
    is_deeply $generated, $expected,
        "generated ids correct (default first_id)";
}

{
    my $expected     = [5 .. 20];
    my $generated    = [];
    my $id_generator = $pkg->new(first_id => $expected->[0]);
    isa_ok $id_generator, $pkg;
    ok $id_generator->does("Catmandu::IdGenerator"),
        "an object of class '$pkg' does 'Catmandu::IdGenerator'";
    push @$generated, map {$id_generator->generate} @$expected;
    is_deeply $generated, $expected,
        "generated ids correct (custom first_id)";
}

done_testing;
