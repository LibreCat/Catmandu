#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::Memory';
    use_ok $pkg;
}

require_ok $pkg;

my $store = $pkg->new;

ok $store , 'got a store';

my $bags = $store->bag();

ok $bags , 'store->bag()';

isa_ok $bags , 'Catmandu::Store::File::Memory::Index';

ok $bags , 'create memory store';

ok $bags->add({_id => '1234'}), 'adding `1234` bag';

throws_ok {$store->bag('1235')} 'Catmandu::Error', 'bag(1235) doesnt exist';

lives_ok {$store->bag('1234')} 'bag(1234) exists';

done_testing;
