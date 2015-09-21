#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::split_date';
    use_ok $pkg;
}

sub test_expand {
    my $expect = pop;
    my $data = pop;
    is_deeply $pkg->new(@_)->fix($data), $expect;
}

test_expand 'date',
    { date => '2001-11-09' },
    { date => { year => 2001, month => 11, day => 9 } };

test_expand 'date_created',
    { date_created => '2001:11' },
    { date_created =>  { year => 2001, month => 11 } };

done_testing 3;
