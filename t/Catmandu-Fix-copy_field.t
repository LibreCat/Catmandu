#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::copy_field';
    use_ok $pkg;
}

is_deeply
    $pkg->new('old', 'new')->fix({old => 'old'}),
    {old => 'old', new => 'old'},
    "copy field at root";

is_deeply
    $pkg->new('old', 'deeply.nested.$append.new')->fix({old => 'old'}),
    {old => 'old', deeply => {nested => [{new => 'old'}]}},
    "copy field creates intermediate path";

is_deeply
    $pkg->new('old.*', 'deeply.nested.$append.new')->fix({old => ['old', 'older']}),
    {old => ['old', 'older'], deeply => {nested => [{new => 'old'}, {new => 'older'}]}},
    "copy field creates intermediate path (with wildcard)";

done_testing 4;
