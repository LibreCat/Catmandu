#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;
use Cpanel::JSON::XS;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_null';
    use_ok $pkg;
}

my $cond = $pkg->new('foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({foo => undef}),
    {foo => undef,  test => 'pass'};

is_deeply
    $cond->fix({foo => {}}),
    {foo => {},  test => 'fail'};

is_deeply
    $cond->fix({foo => 0}),
    {foo => 0,  test => 'fail'};

is_deeply
    $cond->fix({}),
    {test => 'fail'};

done_testing;
