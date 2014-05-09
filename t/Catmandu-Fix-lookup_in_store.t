#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::lookup_in_store';
    use_ok $pkg;
}

require_ok $pkg;

is_deeply
    $pkg->new('planet', 'test')->fix({planet => 'Earth'}),
    {planet => { _id => 'Earth' , value => 'Terra' } };

is_deeply
    $pkg->new('planet', 'test')->fix({planet => 'Bartledan'}),
    {planet => 'Bartledan'};

is_deeply
    $pkg->new('planet', 'test', 'delete', 1)->fix({planet => 'Bartledan'}),
    {};

is_deeply
    $pkg->new('planets.*', 'test', 'delete', 1)->fix({planets => ['Bartledan', 'Earth']}),
    {planets => [{ _id => 'Earth' , value => 'Terra' }]};

is_deeply
    $pkg->new('planet', 'test', 'default', 'Mars')->fix({planet => 'Bartledan'}),
    {planet => 'Mars'};

done_testing 7;
