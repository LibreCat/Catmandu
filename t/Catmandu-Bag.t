#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Catmandu::Util;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Bag';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::BagWithoutGet;
    use Moo;
    sub generator  { }
    sub add        { }
    sub delete     { }
    sub delete_all { }

    package T::BagWithoutDelete;
    use Moo;
    sub generator  { }
    sub add        { }
    sub get        { }
    sub delete_all { }

    package T::BagWithoutDeleteAll;
    use Moo;
    sub generator { }
    sub add       { }
    sub get       { }
    sub delete    { }

    package T::Store;
    use Moo;
    with 'Catmandu::Store';

    package T::Bag;    #mock array based bag
    use Moo;
    use Clone;
    with $pkg;

    has bag => (is => 'ro', default => sub {[]});

    sub generator {
        my $bag = $_[0]->bag;
        my $n   = 0;
        sub {
            return $bag->[$n++] if $n < @$bag;
            return;
        };
    }

    sub add {
        my ($self, $data) = @_;
        $data = Clone::clone($data);
        my $bag = $self->bag;
        my $key = $self->id_key;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{$key} eq $data->{$key}) {
                $bag->[$i] = $data;
                return;
            }
        }
        push @$bag, $data;
    }

    sub get {
        my ($self, $id) = @_;
        my $bag = $self->bag;
        my $key = $self->id_key;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{$key} eq $id) {
                return $bag->[$i];
            }
        }
        return;
    }

    sub delete {
        my ($self, $id) = @_;
        my $bag = $self->bag;
        my $key = $self->id_key;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{$key} eq $id) {
                splice @$bag, $i, 1;
                return;
            }
        }
    }

    sub delete_all {
        my ($self) = @_;
        my $bag = $self->bag;
        splice @$bag;
    }

    package T::BagData;
    use Moo;

    package T::IdGenerator;
    use Catmandu::Util;
    use Moo;
    with 'Catmandu::Bag::IdGenerator';

    sub generate {
        my ($self, $bag) = @_;
        die unless Catmandu::Util::is_instance($bag, 'T::Bag');
        1;
    }
}

throws_ok {Role::Tiny->apply_role_to_package('T::BagWithoutGet', $pkg)}
qr/missing get/;
throws_ok {Role::Tiny->apply_role_to_package('T::BagWithoutDelete', $pkg)}
qr/missing delete/;
throws_ok {Role::Tiny->apply_role_to_package('T::BagWithoutDeleteAll', $pkg)}
qr/missing delete_all/;

my $b = T::Bag->new(store => T::Store->new, name => 'test');
ok $b->does('Catmandu::Iterable');
ok $b->does('Catmandu::Addable');
can_ok $b, 'generate_id';
can_ok $b, 'commit';
can_ok $b, 'exists';
can_ok $b, 'get_or_add';
can_ok $b, 'to_hash';

ok Catmandu::Util::is_value($b->generate_id);

throws_ok {$b->add(T::BagData->new)} qr/should be hash ref/;
throws_ok {$b->add([])} qr/should be hash ref/;
throws_ok {$b->add("")} qr/should be hash ref/;

throws_ok {$b->add({_id => T::BagData->new})} qr/should be value/;
throws_ok {$b->add({_id => *STDOUT})} qr/should be value/;

lives_ok {$b->add({_id => ""})};
lives_ok {$b->add({_id => "0"})};
lives_ok {$b->add({_id => 0})};

$b->add_many([{}, {}, {}]);
$b->delete_all;
is $b->count, 0;

my $data = {a => {shrimp => 'shrieks'}};

$b->add($data);
ok Catmandu::Util::is_value($data->{_id});
is_deeply $b->get($data->{_id}), $data;
is $b->exists($data->{_id}), 1;

$b->delete($data->{_id});
is $b->get($data->{_id}),    undef;
is $b->exists($data->{_id}), 0;

$b->add($data);

is_deeply $b->get_or_add($data->{_id}, {a => {pony => 'wails'}}), $data;

is_deeply $b->to_hash, {$data->{_id} => $data};

$b->touch('datestamp');
ok $b->all(sub {$_[0]->{datestamp}});

# store custom key_prefix

$b = T::Bag->new(store => T::Store->new(key_prefix => 'my_'), name => 'test');
is $b->id_key, 'my_id';

# custom id_key

$b = T::Bag->new(
    store  => T::Store->new(key_prefix => '__'),
    name   => 'test',
    id_key => 'my_id'
);
$data = $b->add({});
is $data->{_id},  undef;
is $data->{__id}, undef;
ok exists($data->{my_id});
isnt $b->get($data->{my_id}), undef;
$b->delete($data->{my_id});
is $b->get($data->{my_id}), undef;

# id_field alias

$b = T::Bag->new(
    store    => T::Store->new(key_prefix => '__'),
    name     => 'test',
    id_field => 'my_id'
);
$data = $b->add({});
is $data->{_id},  undef;
is $data->{__id}, undef;
ok exists($data->{my_id});
isnt $b->get($data->{my_id}), undef;
$b->delete($data->{my_id});
is $b->get($data->{my_id}), undef;

# custom id generator

$b = T::Bag->new(
    store        => T::Store->new,
    name         => 'test',
    id_generator => T::IdGenerator->new,
);

lives_ok {$b->generate_id};

done_testing;
