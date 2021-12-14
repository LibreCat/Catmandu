#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::uri_encode';
    use_ok $pkg;
}

is_deeply $pkg->new('name')->fix({name => 'café'}), {name => "caf%C3%A9"},
    "escape utf8 string from French";

is_deeply $pkg->new('name')->fix({name => 'ὁ τῶν Πέρσων βασιλεύς'}),
    {name =>
        "%E1%BD%81%20%CF%84%E1%BF%B6%CE%BD%20%CE%A0%CE%AD%CF%81%CF%83%CF%89%CE%BD%20%CE%B2%CE%B1%CF%83%CE%B9%CE%BB%CE%B5%CF%8D%CF%82"
    }, "escape utf8 string from Greek";

done_testing;
