#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::ConfigData;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    #unless (Catmandu::ConfigData->feature('')) {
    #    plan skip_all => 'feature disabled';
    #}
    $pkg = 'Catmandu::Counter';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Counter;

    use Moo;

    with 'Catmandu::Counter';
}

my $c = T::Counter->new;

can_ok $c, 'count';
can_ok $c, 'inc_count';
can_ok $c, 'dec_count';
can_ok $c, 'reset_count';

is $c->count, 0;

$c->inc_count;
is $c->count, 1;

$c->dec_count;
is $c->count, 0;
$c->dec_count;
is $c->count, 0;

$c->inc_count;
$c->reset_count;
is $c->count, 0;

done_testing 11;

