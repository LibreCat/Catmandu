#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::Util qw(is_instance);
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::move';
    use_ok $pkg;
}

ok is_instance($pkg->new('foo', 'bar'), 'Catmandu::Fix::move_field');

done_testing;
