#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg1;
my $pkg2;

BEGIN {
    $pkg1 = 'Catmandu::Fix::uri_encode';
    use_ok $pkg1;
    $pkg2 = 'Catmandu::Fix::uri_decode';
    use_ok $pkg2;
}

my $obj    = {name => 'café'};
my $obj2   = {name => 'ὁ τῶν Πέρσων βασιλεύς'};
my $fixer1 = $pkg1->new('name');
my $fixer2 = $pkg2->new('name');

is_deeply $fixer2->fix($fixer1->fix($obj)), {name => "café"},
    "escape and unescape French";

is_deeply $fixer2->fix($fixer1->fix($obj2)),
    {name => "ὁ τῶν Πέρσων βασιλεύς"}, "escape and unescape Greek";

done_testing;
