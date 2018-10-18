#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::eval';
    use_ok $pkg;
}

is_deeply $pkg->new('fixes')->fix({}), +{};

is_deeply $pkg->new('fixes')->fix({fixes => 'add_field(foo,bar)'}),
    +{fixes => 'add_field(foo,bar)', foo => 'bar'};

is_deeply $pkg->new('fixes')->fix({fixes => ['add_field(foo,bar)']}),
    +{fixes => ['add_field(foo,bar)'], foo => 'bar'};

is_deeply $pkg->new('fixes')
    ->fix({fixes => ['add_field(foo,bar)', 'upcase(foo)']}),
    +{fixes => ['add_field(foo,bar)', 'upcase(foo)'], foo => 'BAR'};

is_deeply $pkg->new('fixes')->fix({fixes => {foo => 'bar'}}),
    +{fixes => {foo => 'bar'}};

done_testing;
