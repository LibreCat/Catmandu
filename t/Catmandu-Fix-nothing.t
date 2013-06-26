#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::nothing';
    use_ok $pkg;
}

my $data = {foo => 'bar'};

is $data, $pkg->new->fix($data), "fixed data is the same object";

done_testing 2;
