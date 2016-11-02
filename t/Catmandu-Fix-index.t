#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::index';
    use_ok $pkg;
}

is_deeply $pkg->new('test', 'c')->fix({test => 'abcde'}),
    {test => '2'}, "index(abcde,c)";

is_deeply $pkg->new('test', 'c','multiple',1)->fix({test => 'abcccde'}),
    {test => [2,3,4]}, "index(abcccde,c)";

is_deeply $pkg->new('test.*', 'c')->fix({test => ['abcde','fgh']}),
    {test => [2,-1]}, "index([abcde,fgh],c)";

is_deeply $pkg->new('test', 'bar')->fix({test => ['foo','bar','bar','foo']}),
    {test => 1}, "index([foo,bar,bar,foo],c)";

is_deeply $pkg->new('test', 'bar', 'multiple', 1)->fix({test => ['foo','bar','bar','foo']}),
    {test => [1,2]}, "index([foo,bar,bar,foo],c, -multiple:1)";

done_testing 6;
