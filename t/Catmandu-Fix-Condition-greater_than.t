#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::greater_than';
    use_ok $pkg;
}

my $cond = $pkg->new('year','1970');

$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({year => '1980'}),
    {year => '1980' , test => 'pass'};

is_deeply
    $cond->fix({year => '1960'}),
    {year => '1960' , test => 'fail'};

$cond = $pkg->new('a.deep.year','1970');

$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({ a => { deep => {year => '1980'} } }),
    { a => { deep => {year => '1980'} }  , test => 'pass'};

is_deeply
    $cond->fix({ a => { deep => {year => '1960'} } }),
    { a => { deep => {year => '1960'} } , test => 'fail'};

done_testing 5;
