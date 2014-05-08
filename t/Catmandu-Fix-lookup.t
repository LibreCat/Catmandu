#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::lookup';
    use_ok $pkg;
}

is_deeply
    $pkg->new('planet', 't/planets.csv')->fix({planet => 'Earth'}),
    {planet => 'Terra'};

is_deeply
    $pkg->new('planet', 't/planets.csv')->fix({planet => 'Bartledan'}),
    {planet => 'Bartledan'};

is_deeply
    $pkg->new('planet', 't/planets.csv', 'delete', 1)->fix({planet => 'Bartledan'}),
    {};

is_deeply
    $pkg->new('planets.*', 't/planets.csv', 'delete', 1)->fix({planets => ['Bartledan', 'Earth']}),
    {planets => ['Terra']};

is_deeply
    $pkg->new('planet', 't/planets.csv', 'default', 'Mars')->fix({planet => 'Bartledan'}),
    {planet => 'Mars'};

is_deeply
    $pkg->new('planet', 't/planets.tab', 'sep_char', "\t")->fix({planet => 'Earth'}),
    {planet => 'Terra'},
    "pass csv options";

done_testing 7;
