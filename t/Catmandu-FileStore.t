#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::FileStore';
    use_ok $pkg;
}

require_ok $pkg;

{

    package T::Store;
    use Moo;
    with $pkg;

    package T::Store::Index;
    use Moo;
    with 'Catmandu::Bag';
    with 'Catmandu::FileBag';

    sub generator  { }
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    package T::Store::Bag;
    use Moo;
    with 'Catmandu::Bag';
    with 'Catmandu::FileBag';

    sub generator  { }
    sub add        { }
    sub get        { }
    sub delete     { }
    sub delete_all { }

    package T::CustomIndexClass;
    use Moo;
    extends 'T::Store::Index';

    has prop => (is => 'ro');

    package T::CustomBagClass;
    use Moo;
    extends 'T::Store::Bag';

    has prop => (is => 'ro');
}

note("create a new store");
my $s = T::Store->new;
can_ok $s, 'bag_class';
can_ok $s, 'default_bag';
can_ok $s, 'bag';
can_ok $s, 'index';
is $s->bag_class,   'T::Store::Bag';
is $s->default_bag, 'index';

note("create a custom store");
$s = T::Store->new(
    bag_class   => 'T::CustomBagClass',
    index_class => 'T::CustomIndexClass'
);
is $s->bag_class,   'T::CustomBagClass';
is $s->index_class, 'T::CustomIndexClass';

my $b = $s->bag;
isa_ok $b, $s->index_class;
is $s->bag,   $b;
is $b->store, $s;
is $b->name,  'index';

ok !$s->bag('foo'), 'unkown bag';

note("options");
$s = T::Store->new(
    index_class => 'T::CustomIndexClass',
    bags        => {index => {prop => 'val', store => 'junk', name => 'junk'}}
);
is $s->index->prop,    'val',  "options are passed to bag";
isnt $s->index->store, 'junk', "store can't be overriden";
isnt $s->index->name,  'junk', "name can't be overriden";

note("default options");
$s = T::Store->new(
    index_class     => 'T::CustomIndexClass',
    default_options => {prop => 'bar'},
    bags            => {index => {store => 'junk', name => 'junk'}}
);
is $s->index->prop, 'bar';

$s = T::Store->new(
    index_class     => 'T::CustomIndexClass',
    default_options => {prop => 'bar'},
    bags => {index => {prop => 'baz', store => 'junk', name => 'junk'}}
);
is $s->index->prop, 'baz';

note("plugins");
$b = T::Store->new(bags => {index => {plugins => [qw(Datestamps)]}})->index;
ok $b->does('Catmandu::Plugin::Datestamps'), 'apply plugins';

$b = T::Store->new(default_plugins => [qw(Datestamps)])->index;
ok $b->does('Catmandu::Plugin::Datestamps'), 'apply default plugins';

$b = T::Store->new(
    default_plugins => [qw(Datestamps)],
    bags            => {index => {plugins => [qw(Versioning)]}}
)->index;
ok $b->does('Catmandu::Plugin::Datestamps')
    && $b->does('Catmandu::Plugin::Versioning'), 'prepend default plugins';

done_testing();
