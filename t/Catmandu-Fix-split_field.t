#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::split_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('splitme', ',')->fix({splitme => "a,b,c"}),
    {splitme => ["a", "b", "c"]},
    "split value";

is_deeply
    $pkg->new('many.*.splitme', ',')->fix({many => [{splitme => "a,b,c"}, {splitme => "a,b,c"}]}),
    {many => [{splitme => ["a", "b", "c"]}, {splitme => ["a", "b", "c"]}]},
    "split wildcard values";

is_deeply
    $pkg->new('splitme', ',')->fix({splitme => ["a", "b", "c"]}),
    {splitme => ["a", "b", "c"]},
    "only split values";

done_testing 4;
