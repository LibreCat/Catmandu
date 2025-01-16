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

is_deeply $pkg->new('remove')->fix({remove => 'me', keep => 'me'}),
    {keep => 'me'}, "remove field at root";

is_deeply $pkg->new('many.*.remove')->fix(
    {
        many =>
            [{remove => 'me', keep => 'me'}, {remove => 'me', keep => 'me'}]
    }
    ),
    {many => [{keep => 'me'}, {keep => 'me'}]},
    "remove nested field with wildcard";

is_deeply $pkg->new("''")->fix({a => 'A', '' => 'Empty', c => 'C'}),
    {a => 'A', c => 'C'}, 'remove empty';

is_deeply $pkg->new("\"\"")->fix({a => 'A', '' => 'Empty', c => 'C'}),
    {a => 'A', c => 'C'}, 'remove empty (double quotes)';

is_deeply $pkg->new("x.''")->fix({x => {a => 'A', '' => 'Empty', c => 'C'}}),
    {x => {a => 'A', c => 'C'}}, 'remove nested empty';

is_deeply $pkg->new("\"x y z\"")
    ->fix({a => 'A', 'x y z' => 'Empty', c => 'C'}), {a => 'A', c => 'C'},
    'remove keys with spaces';

done_testing 7;
