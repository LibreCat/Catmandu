#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Validator::Mock';
    use_ok $pkg;
}

require_ok $pkg;

my $rec = {};

my $v = Catmandu::Validator::Mock->new;

ok $v->is_valid($rec), 'all items valid by default';

$v->reject(1);
ok !$v->is_valid($rec), 'all items invalid if reject is true';
is_deeply $v->last_errors, ['item is invalid'], 'default error message';

$v->message('Oops!');
$v->is_valid($rec);
is_deeply $v->last_errors, ['Oops!'], 'custom error message';

done_testing;
