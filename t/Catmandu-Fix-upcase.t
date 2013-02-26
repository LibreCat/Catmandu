#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::upcase';
    use_ok $pkg;
}

is_deeply
    $pkg->new('name')->fix({name => 'joe'}),
    {name => "JOE"},
    "upcase value";

is_deeply
    $pkg->new('names.*.name')->fix({names => [{name => 'joe'}, {name => 'rick'}]}),
    {names => [{name => 'JOE'}, {name => 'RICK'}]},
    "upcase wildcard values";

done_testing 3;
