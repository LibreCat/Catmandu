#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::join_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('joinme', ',')->fix({joinme => ['J', 'O', 'I', 'N']}),
    {joinme => "J,O,I,N"},
    "join value";

is_deeply
    $pkg->new('many.*.joinme', ',')->fix({many => [{joinme => ['J', 'O', 'I', 'N']}, {joinme => ['J', 'O', 'I', 'N']}]}),
    {many => [{joinme => "J,O,I,N"}, {joinme => "J,O,I,N"}]},
    "join wildcard values";

is_deeply
    $pkg->new('joinme', ',')->fix({joinme => {skip => 'me'}}),
    {joinme => {skip => 'me'}},
    "only join array values";

is_deeply
    $pkg->new('joinme', ',')->fix({joinme => ['J', {skip => 'me'}, 'I', 'N']}),
    {joinme => "J,I,N"},
    "only join array values";

is_deeply
    $pkg->new('joinme', '/')->fix({joinme => ['J', 'O', 'I', 'N']}),
    {joinme => "J/O/I/N"},
    "join value";

done_testing 6;
