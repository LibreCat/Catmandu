#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::sleep';
    use_ok $pkg;
}

is_deeply $pkg->new('1', 'MILLISECOND')->fix({name => 'Joe'}),
    {name => "Joe"}, "slept didn't change the data";

done_testing 2;
