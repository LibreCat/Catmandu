#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $pkg;
my $pkg2;
BEGIN {
    $pkg = 'Catmandu::Fix::map';
    use_ok $pkg;
}

is_deeply $pkg->new('t/field_mapping.csv')
    ->fix({title => "Computational Biology"}),
    {Title => "Computational Biology"}, "map simple field";

is_deeply $pkg->new('t/field_mapping.csv')->fix(
    {
        title  => "Computational Biology",
        author => "C. Ungewitter",
        id     => "3279423874"
    }
    ),
    {
    Title      => "Computational Biology",
    Author     => "C. Ungewitter",
    Identifier => "3279423874"
    },
    "map several fields";

is_deeply $pkg->new('t/field_mapping.csv')->fix({publisher => "Springer"}),
    {Publisher => [{nested => "Springer"}]}, "map nested field";

is_deeply $pkg->new('t/field_mapping.csv')->fix({publisher => "Springer"}),
    {Publisher => [{nested => "Springer"}]}, "map nested field";

is_deeply $pkg->new('t/field_mapping.csv')->fix({deeply => {nested => ["XX"]}}),
    {test => "XX", deeply => {nested => []}}, "map nested field";

done_testing;
