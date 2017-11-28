#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_false';
    use_ok $pkg;
}

my $cond = $pkg->new('foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

# Integers
is_deeply $cond->fix({foo => 1}), {foo => 1, test => 'fail'};

is_deeply $cond->fix({foo => 0}), {foo => 0, test => 'pass'};

# Strings
is_deeply $cond->fix({foo => "true"}), {foo => "true", test => 'fail'};

is_deeply $cond->fix({foo => "false"}), {foo => "false", test => 'pass'};

# Boolean
my $hash = decode_json(qq|{"foo":true}|);
is_deeply $cond->fix($hash), {%$hash, test => 'fail'};

my $hash2 = decode_json(qq|{"foo":false}|);
is_deeply $cond->fix($hash2), {%$hash2, test => 'pass'};

# Strict
$cond = $pkg->new('foo', 'strict', 1);
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({foo => 0}), {foo => 0, test => 'fail'};

is_deeply $cond->fix({foo => '0'}), {foo => '0', test => 'fail'};

is_deeply $cond->fix({foo => 'false'}), {foo => 'false', test => 'fail'};

is $cond->fix({foo => Cpanel::JSON::XS::false})->{test}, 'pass';
is $cond->fix({foo => Cpanel::JSON::XS::true})->{test}, 'fail';

done_testing;
