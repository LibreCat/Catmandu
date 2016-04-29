#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_string';
    use_ok $pkg;
}

my $cond = $pkg->new('foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({foo => 1}), {foo => 1, test => 'fail'};

is_deeply $cond->fix({foo => 0}), {foo => 0, test => 'fail'};

is_deeply $cond->fix({foo => -1}), {foo => -1, test => 'fail'};

is_deeply $cond->fix({foo => 1.1}), {foo => 1.1, test => 'fail'};

is_deeply $cond->fix({foo => -1.1}), {foo => -1.1, test => 'fail'};

is_deeply $cond->fix({foo => "1.1"}), {foo => "1.1", test => 'fail'};

is_deeply $cond->fix({foo => "1.1x"}), {foo => "1.1x", test => 'pass'};

is_deeply $cond->fix({foo => ["1.1x"]}), {foo => ["1.1x"], test => 'fail'};

done_testing;
