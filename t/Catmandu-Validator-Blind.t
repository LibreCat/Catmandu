#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Validator::Blind';
    use_ok $pkg;
}

require_ok $pkg;

my $rec = { answer => 42 };

my $v = Catmandu::Validator::Blind->new();

is $v->validate($rec), $rec, 'all items valid by default';
is $v->rate, 0, 'rate 0%';

$v->rate(1);
is $v->validate($rec), undef, 'all items invalid with rate 1';
is_deeply $v->last_errors, ['item randomly marked as invalid'], 'error message';

$v->message('Oops!');
is $v->validate($rec), undef, 'all items invalid with rate 1';
is_deeply $v->last_errors, ['Oops!'], 'custom error message';

done_testing;
