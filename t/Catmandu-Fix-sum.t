#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::sum';
    use_ok $pkg;
}

require_ok $pkg;

lives_ok { $pkg->new('numbers')->fix({ numbers => [1,2] }) };

is_deeply 
$pkg->new('numbers')->fix({ numbers => [1,2] }), 
{ numbers => 3 }, "Simple sum ok";

# Fibonacci sequence now!
is_deeply 
$pkg->new('numbers')->fix({ numbers => [1,1,2,3,5,8,13,21] }), 
{ numbers => 54 }, "Fibbonaci sum ok";

is_deeply 
$pkg->new('numbers')->fix({ numbers => [1.234, 4.653, 4.5] }), 
{ numbers => 10.387 }, "Float sum ok";

dies_ok { $pkg->new('numbers')->fix({ numbers => ['hello', 'world'] }) };

done_testing 7;
