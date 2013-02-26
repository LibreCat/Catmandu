#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::append';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name', 'y')->fix({name => 'joe'}),
    {name => "joey"},
    "append to value";

is_deeply
    $pkg->new('names.*.name', 'y')->fix({names => [{name => 'joe'}, {name => 'rick'}]}),
    {names => [{name => 'joey'}, {name => 'ricky'}]},
    "append to wildcard values";

done_testing 3;
