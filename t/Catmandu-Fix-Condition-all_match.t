#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::all_match';
    use_ok $pkg;
}

my $cond = $pkg->new('string', 'foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({string => 'barfoobar'}),
    { string => 'barfoobar', test => 'pass'};

is_deeply
    $cond->fix({string => 'onlybar'}),
    { string => 'onlybar', test => 'fail'};

$cond = $pkg->new( 'string.*', 'foo');

$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({string => [ 'foo', 'barfoobar' ]}),
    { string => [ 'foo', 'barfoobar' ], test => 'pass'};

is_deeply
    $cond->fix({string => [ 'bar1', 'bar2' ]}),
    { string => [ 'bar1', 'bar2' ], test => 'fail'};

done_testing 5;
