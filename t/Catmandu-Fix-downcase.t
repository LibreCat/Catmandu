#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::downcase';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name')->fix({name => 'JOE'}),
    {name => "joe"},
    "downcase value";

is_deeply
    $pkg->new('names.*.name')->fix({names => [{name => 'JOE'}, {name => 'RICK'}]}),
    {names => [{name => 'joe'}, {name => 'rick'}]},
    "downcase wildcard values";

done_testing 3;
