#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Validator::Env';
    use_ok $pkg;
}

require_ok $pkg;

my $name = 'CATMANDU_VALIDATOR_ENV';
my $rec = { answer => 42 };

my $v = Catmandu::Validator::Env->new();

is $v->validate($rec), $rec, 'all items valid by default';
is $v->variable, $name, $name;

$ENV{$name} = '';
is $v->validate($rec), $rec, 'empty string taken as false';

$ENV{$name} = 0;
is $v->validate($rec), $rec, '0 taken as false';

$ENV{$name} = 1;
is $v->validate($rec), undef, 'all items invalid';
is_deeply $v->last_errors, ['item marked as invalid'], 'error message';

$v->variable("TEST_$name");
$ENV{"TEST_$name"} = 1;
$v->message('Oops!');
is $v->validate($rec), undef, 'configured variable';
is_deeply $v->last_errors, ['Oops!'], 'custom error message';

done_testing;
