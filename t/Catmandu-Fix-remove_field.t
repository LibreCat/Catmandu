#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::remove_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('remove')->fix({remove => 'me', keep => 'me'}),
    {keep => 'me'},
    "remove field at root";

is_deeply
    $pkg->new('many.*.remove')->fix({many => [{remove => 'me', keep => 'me'}, {remove => 'me', keep => 'me'}]}),
    {many => [{keep => 'me'}, {keep => 'me'}]},
    "remove nested field with wildcard";

done_testing 3;
