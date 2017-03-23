#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::rename';
    use_ok $pkg;
}

is_deeply $pkg->new('dots', '\.', '-')->fix({dots => {'a.b' => [{'c.d' => ""}]}}),
    {dots => {'a-b' => [{'c-d' => ""}]}};

done_testing;
