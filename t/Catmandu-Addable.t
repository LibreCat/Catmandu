#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Addable';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [];

{

    package T::AddableWithoutAdd;
    use Moo;

    package T::Addable;
    use Moo;
    with $pkg;

    sub add {
        push @$data, $_[1];
    }

    package T::WithoutGenerator;
    use Moo;

    package T::WithGenerator;
    use Moo;

    sub generator {
        sub { }
    }
}

throws_ok {Role::Tiny->apply_role_to_package('T::AddableWithoutAdd', $pkg)}
qr/missing add/;

my $a = T::Addable->new;
can_ok $a, 'add_many';

is_deeply $a->add({a => 'pony'}), {a => 'pony'}, 'add returns data added';

$data = [];
$a->add(undef);
is_deeply $data, [], 'undef gets rejected';

lives_ok {$a->add_many({})} 'add_many takes a single hash ref';
lives_ok {$a->add_many([])} 'add_many takes an array ref';
lives_ok {
    $a->add_many(sub { })
}
'add_many takes a generator code ref';
lives_ok {$a->add_many(T::WithGenerator->new)}
'add_many takes an object with a generator method';
throws_ok {$a->add_many(T::WithoutGenerator->new)}
qr/should be able to generator/;

$data = [];
is $a->add_many([1, 2, 3]), 3, 'add_many returns count of data added';
is_deeply $data, [1, 2, 3], 'add_many passes all data to add';

require Catmandu::ArrayIterator;
$data = [];
$a    = T::Addable->new;
Catmandu::ArrayIterator->new([0, 1])->add_to($a);
is_deeply $data, [0, 1], 'add_to on Iterable';

done_testing;
