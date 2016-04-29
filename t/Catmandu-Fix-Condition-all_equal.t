#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Catmandu::Fix::set_field;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::all_equal';
    use_ok $pkg;
}

my $cond = $pkg->new('string', 'foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({string => 'foo'}), {string => 'foo', test => 'pass'};

is_deeply $cond->fix({string => 'foobar'}),
    {string => 'foobar', test => 'fail'};

$cond = $pkg->new('string.*', 'foo');

$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({string => ['foo', 'foo']}),
    {string => ['foo', 'foo'], test => 'pass'};

is_deeply $cond->fix({string => ['foo', 'foobar']}),
    {string => ['foo', 'foobar'], test => 'fail'};

done_testing 5;
