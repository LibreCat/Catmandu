#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::uniq';
    use_ok $pkg;
}

is_deeply
    $pkg->new('tags')->fix({tags => ["foo", "bar","bar"]}),
    {tags => ["bar","bar","foo"]};

done_testing;
