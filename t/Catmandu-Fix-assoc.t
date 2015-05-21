#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::assoc';
    use_ok $pkg;
}

is_deeply
    $pkg->new('fields', 'pairs.*.key', 'pairs.*.val')->fix({pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]}),
    {fields => {subject => 'Perl', year => 2009}, pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]};

is_deeply
    $pkg->new('', 'pairs.*.key', 'pairs.*.val')->fix({pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]}),
    {subject => 'Perl', year => 2009, pairs => [{key => 'year', val => 2009}, {key => 'subject', val => 'Perl'}]},
    "add to root";

done_testing 3;
