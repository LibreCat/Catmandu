#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $pkg;
my $pkg2;
BEGIN {
    $pkg = 'Catmandu::Fix::mapping';
    use_ok $pkg;
}

is_deeply $pkg->new('t/field_mapping.csv', sep_char => ';')
    ->fix({title => "Computational Biology"}),
    {Title => "Computational Biology"}, "map simple field";

is_deeply $pkg->new('t/field_mapping.csv', sep_char => ';')->fix(
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

is_deeply $pkg->new('t/field_mapping.csv', sep_char => ';')->fix({publisher => "Springer"}),
    {Publisher => [{nested => "Springer"}]}, "map nested field";

is_deeply $pkg->new('t/field_mapping.csv', sep_char => ';', 'keep', 1)->fix({publisher => "Springer"}),
    {Publisher => [{nested => "Springer"}], , publisher => "Springer"}, "map nested field  with keep option";

is_deeply $pkg->new('t/field_mapping.csv', 'keep', 1, sep_char => ';')->fix({publisher => "Springer"}),
    {Publisher => [{nested => "Springer"}], , publisher => "Springer"}, "map nested field  with keep option";

done_testing;
