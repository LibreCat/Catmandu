#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::collapse';
    use_ok $pkg;
}

is_deeply
    $pkg->new()->fix({names => [{name => 'joe'}, {name => 'rick'}]}),
    {'names.0.name' => "joe", 'names.1.name' => "rick"},
    "data is flattened";

done_testing 2;
