#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Path::simple';
    use_ok $pkg;
}
require_ok $pkg;

my $p = $pkg->new(path => 'mydata');
$p->creator(value => {my => {data => {}}})->(my $rec = {});
is_deeply $rec, {mydata => {my => {data => {}}}}, "value isn't stringified";

done_testing;
