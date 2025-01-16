#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::clone';
    use_ok $pkg;
}

my $data   = {foo => 'bar'};
my $cloned = $pkg->new->fix($data);

is_deeply $data, $cloned, "cloned data is equal";
isnt $data, $cloned, "cloned data is another object";

done_testing;
