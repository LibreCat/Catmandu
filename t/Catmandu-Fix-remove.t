#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::Util qw(is_instance);
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::remove';
    use_ok $pkg;
}

ok is_instance($pkg->new('foo'), 'Catmandu::Fix::remove_field');

done_testing;
