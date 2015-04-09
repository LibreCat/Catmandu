#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_equal';
    use_ok $pkg;
}

my $cond = $pkg->new('foo','bar');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

# Integers
is_deeply
    $cond->fix({foo => 1 ,bar => 1}),
    {foo => 1 , bar => 1, test => 'pass'};

is_deeply
    $cond->fix({foo => 1 , bar => 2}),
    {foo => 1 , bar => 2, test => 'fail'};

# Strings
is_deeply
    $cond->fix({foo => "hotel" ,bar => "hotel"}),
    {foo => "hotel" , bar => "hotel", test => 'pass'};

is_deeply
    $cond->fix({foo => "hotel" , bar => "tango"}),
    {foo => "hotel" , bar => "tango", test => 'fail'};

# Empty fields
is_deeply
    $cond->fix({foo => "" , bar => ""}),
    {foo => "" , bar => "", test => 'pass'};

is_deeply
    $cond->fix({foo => undef , bar => undef}),
    {foo => undef , bar => undef, test => 'pass'};   

is_deeply
    $cond->fix({}),
    {test => 'fail'};  

# Arrays
is_deeply
    $cond->fix({foo => [1,2,3] , bar => [1,2,3] }),
    {foo => [1,2,3] , bar => [1,2,3], test => 'pass'};

is_deeply
    $cond->fix({foo => [1,2,3] , bar => [3,2,1] }),
    {foo => [1,2,3] , bar => [3,2,1], test => 'fail'};

is_deeply
    $cond->fix({foo => [1,2,3] , bar => [1,2,3,4] }),
    {foo => [1,2,3] , bar => [1,2,3,4], test => 'fail'};

is_deeply
    $cond->fix({foo => [] , bar => [] }),
    {foo => [] , bar => [], test => 'pass'};

# Hashes
is_deeply
    $cond->fix({foo => {a => 'b'} , bar => {a => 'b'} }),
    {foo => {a => 'b'} , bar => {a => 'b'}, test => 'pass'};

# ... perl weirdnes ...
is_deeply
    $cond->fix({foo => {a => 'b'} , bar => [ 'a' , 'b'] }),
    {foo => {a => 'b'} , bar => [ 'a' , 'b'], test => 'pass'};

is_deeply
    $cond->fix({foo => {a => 'b', c => [0,1]} , bar => {a => 'b' , c => [0,1]} }),
    {foo => {a => 'b', c => [0,1]} , bar => {a => 'b', c => [0,1]}, test => 'pass'};

done_testing 15;
