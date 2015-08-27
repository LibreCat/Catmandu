#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::add_to_exporter';
    use_ok $pkg;
}

done_testing 1;