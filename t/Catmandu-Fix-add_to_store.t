#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::add_to_store';
    use_ok $pkg;
}

Catmandu->config->{store}{test} = {
    package => "Hash",
};

my $bag = Catmandu->store('test')->bag('test');

my $rec = {add => {_id => 1}};

$pkg->new('add', 'test', '-bag', 'test')->fix($rec);

is_deeply $rec->{add}, $bag->get(1);

done_testing 2;

