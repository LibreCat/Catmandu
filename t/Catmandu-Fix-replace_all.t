#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::replace_all';
    use_ok $pkg;
}

is_deeply $pkg->new('date', '\d{2}', '01')->fix({date => "July 23"}),
    {date => "July 01"};

is_deeply $pkg->new('date', '(\d{2})', '${1}th')->fix({date => "July 23"}),
    {date => "July 23th"}, "interpolation works";

is_deeply $pkg->new('words', '/b', '')->fix({words => "/bar"}),
    {words => "ar"}, "Slashes";

done_testing 4;
