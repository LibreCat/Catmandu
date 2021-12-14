#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;

BEGIN {
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
    with 'Catmandu::Bag';

    sub generator  { }
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    package T::CustomBagClass;
    use Moo;
    extends 'T::Store::Bag';

    has prop => (is => 'ro');
}

my $s = T::Store->new;
can_ok $s, 'bag_class';
can_ok $s, 'default_bag';
can_ok $s, 'bag';

is $s->bag_class, 'T::Store::Bag';
$s = T::Store->new(bag_class => 'T::CustomBagClass');
is $s->bag_class, 'T::CustomBagClass';

is $s->default_bag, 'data';

my $b = $s->bag;
isa_ok $b, $s->bag_class;
is $s->bag,   $b;
is $b->store, $s;
is $b->name,  'data';
$b = $s->bag('foo');
is $b->name, 'foo';
$s = T::Store->new(
    bag_class => 'T::CustomBagClass',
    bags      => {foo => {prop => 'val', store => 'junk', name => 'junk'}}
);
is $s->bag('foo')->prop,    'val',  "options are passed to bag";
isnt $s->bag('foo')->store, 'junk', "store can't be overriden";
isnt $s->bag('foo')->name,  'junk', "name can't be overriden";

# default options

$s = T::Store->new(
    bag_class       => 'T::CustomBagClass',
    default_options => {prop => 'bar'},
    bags            => {foo  => {store => 'junk', name => 'junk'}}
);
is $s->bag('foo')->prop, 'bar';

$s = T::Store->new(
    bag_class       => 'T::CustomBagClass',
    default_options => {prop => 'bar'},
    bags => {foo => {prop => 'baz', store => 'junk', name => 'junk'}}
);
is $s->bag('foo')->prop, 'baz';

# custom key_prefix

is(T::Store->new->key_prefix,                            '_');
is(T::Store->new(key_prefix => 'catmandu_')->key_prefix, 'catmandu_');

# there are more key_prefix tests in Catmandu-Bag.t and
# Catmandu-Plugin-Versioning.t

# custom store wide id_key

$s = T::Store->new(id_key => 'my_id');
is($s->key_prefix,  '_');
is($s->id_key,      'my_id');
is($s->bag->id_key, 'my_id');

$s = T::Store->new(id_field => 'my_id');
is($s->key_prefix,  '_');
is($s->id_key,      'my_id');
is($s->bag->id_key, 'my_id');

# plugins

$b = T::Store->new(bags => {foo => {plugins => [qw(Datestamps)]}})
    ->bag('foo');
ok $b->does('Catmandu::Plugin::Datestamps'), 'apply plugins';

$b = T::Store->new(default_plugins => [qw(Datestamps)])->bag('foo');
ok $b->does('Catmandu::Plugin::Datestamps'), 'apply default plugins';

$b = T::Store->new(
    default_plugins => [qw(Datestamps)],
    bags            => {foo => {plugins => [qw(Versioning)]}}
)->bag('foo');
ok $b->does('Catmandu::Plugin::Datestamps')
    && $b->does('Catmandu::Plugin::Versioning'), 'prepend default plugins';

done_testing;
