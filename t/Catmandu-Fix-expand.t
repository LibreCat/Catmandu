#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::expand';
    use_ok $pkg;
}

is_deeply
    $pkg->new()->fix({'names.0.name' => "joe", 'names.1.name' => "rick"}),
    {names => [{name => 'joe'}, {name => 'rick'}]},
    "data is unflattened";

done_testing 2;
