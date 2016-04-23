#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::parse_text';
    use_ok $pkg;
}

is_deeply $pkg->new('date', '\d\d\d\d-\d\d-\d\d')
    ->fix({date => '2015-03-07'}), {date => '2015-03-07'},
    "parse without capture";

is_deeply $pkg->new('date', '(\d\d\d\d)-(\d\d)-(\d\d)')
    ->fix({date => '2015-03-07'}), {date => ['2015', '03', '07']},
    "parse array value";

is_deeply $pkg->new('date', '(?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)')
    ->fix({date => '2015-03-07'}),
    {date => {year => '2015', month => '03', day => '07'}},
    "parse hash value";

done_testing 4;
