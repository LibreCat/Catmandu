#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::ArrayIterator;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::reject';
    use_ok $pkg;
}

my $fix = $pkg->new;

is $fix->fix({}), undef;
is_deeply $fix->fix([{}]), [];
is_deeply $fix->fix(Catmandu::ArrayIterator->new([{}]))->to_array, [];

done_testing 4;

