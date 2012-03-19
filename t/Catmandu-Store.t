#!/usr/bin/env perl

use strict;
use warnings;
use Catmandu::ConfigData;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    #unless (Catmandu::ConfigData->feature('')) {
    #    plan skip_all => 'feature disabled';
    #}
    $pkg = 'Catmandu::Store';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Store;
    use Moo;
    with $pkg;
    package T::Store::Bag;
    use Moo;
    package T::CustomBagClass;
    use Moo;
    has store => (is => 'ro');
    has name  => (is => 'ro');
    has prop  => (is => 'ro');
}

my $s = T::Store->new;
can_ok $s, 'bag_class';
can_ok $s, 'default_bag';
can_ok $s, 'bags';
can_ok $s, 'bag';

is $s->bag_class, 'T::Store::Bag';
$s = T::Store->new(bag_class => 'T::CustomBagClass');
is $s->bag_class, 'T::CustomBagClass';

is $s->default_bag, 'data';

my $b = $s->bag;
isa_ok $b, $s->bag_class;
is $s->bag, $b;
is $b->store, $s;
is $b->name, 'data';
$b = $s->bag('foo');
is $b->name, 'foo';
$s->bags->{foo}{prop} = 'another val';
$s->bags->{bar}{prop} = 'val';
isnt $s->bag('foo')->prop, 'another val';
is $s->bag('bar')->prop, 'val';

done_testing 16;

