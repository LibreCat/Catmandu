#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::validate';
    use_ok $pkg;
}

my $cond;
my $pass = [Catmandu::Fix::set_field->new('test', 'pass')];
my $fail = [Catmandu::Fix::set_field->new('test', 'fail')];

$cond = $pkg->new('', 'Simple', handler => sub {1});
$cond->pass_fixes($pass);
$cond->fail_fixes($fail);

is_deeply $cond->fix({}), {test => 'pass'};

$cond = $pkg->new('', 'Simple', handler => sub {0});
$cond->pass_fixes($pass);
$cond->fail_fixes($fail);

is_deeply $cond->fix({}), {test => 'fail'};

done_testing;
