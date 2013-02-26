#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::capitalize';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name')->fix({name => 'joe'}),
    {name => "Joe"},
    "capitalize value";

is_deeply
    $pkg->new('names.*.name')->fix({names => [{name => 'joe'}, {name => 'rick'}]}),
    {names => [{name => 'Joe'}, {name => 'Rick'}]},
    "capitalize wildcard values";

done_testing 3;
