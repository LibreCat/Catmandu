#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Data::Util;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Bag';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::BagWithoutGet;
    use Moo;
    sub generator {}
    sub add {}
    sub delete {}
    sub delete_all {}
    package T::BagWithoutDelete;
    use Moo;
    sub generator {}
    sub add {}
    sub get {}
    sub delete_all {}
    package T::BagWithoutDeleteAll;
    use Moo;
    sub generator {}
    sub add {}
    sub get {}
    sub delete {}

    package T::Bag; #mock array based bag
    use Moo;
    use Clone;
    with $pkg;

    has bag => (is => 'ro', default => sub { [] });

    sub generator {
        my $bag = $_[0]->bag;
        my $n = 0;
        sub {
            return $bag->[$n++] if $n < @$bag;
            return;
        };
    }

    sub add {
        my ($self, $data) = @_;
        $data = Clone::clone($data);
        my $bag = $self->bag;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{_id} eq $data->{_id}) {
                $bag->[$i] = $data;
                return;
            }
        }
        push @$bag, $data;
    }

    sub get {
        my ($self, $id) = @_;
        my $bag = $self->bag;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{_id} eq $id) {
                return $bag->[$i];
            }
        }
        return;
    }

    sub delete {
        my ($self, $id) = @_;
        my $bag = $self->bag;
        for (my $i = 0; $i < @$bag; $i++) {
            if ($bag->[$i]->{_id} eq $id) {
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
}

throws_ok { Role::Tiny->apply_role_to_package('T::BagWithoutGet', $pkg) } qr/missing get/;
throws_ok { Role::Tiny->apply_role_to_package('T::BagWithoutDelete', $pkg) } qr/missing delete/;
throws_ok { Role::Tiny->apply_role_to_package('T::BagWithoutDeleteAll', $pkg) } qr/missing delete_all/;

my $b = T::Bag->new;
ok $b->does('Catmandu::Iterable');
ok $b->does('Catmandu::Addable');
can_ok $b, 'generate_id';
can_ok $b, 'commit';
can_ok $b, 'get_or_add';
can_ok $b, 'to_hash';

ok Data::Util::is_value($b->generate_id);

throws_ok { $b->add(T::BagData->new) } qr/should be hash ref/;
throws_ok { $b->add([]) } qr/should be hash ref/;
throws_ok { $b->add("") } qr/should be hash ref/;

throws_ok { $b->add({_id => T::BagData->new}) } qr/should be value/;
throws_ok { $b->add({_id => *STDOUT}) } qr/should be value/;

lives_ok { $b->add({_id => ""})};
lives_ok { $b->add({_id => "0"})};
lives_ok { $b->add({_id => 0})};

$b->add_many([{},{},{}]);
$b->delete_all;
is $b->count, 0;

my $data = {a=>{shrimp=>'shrieks'}};

$b->add($data);
ok Data::Util::is_value($data->{_id});
is_deeply $b->get($data->{_id}), $data;

$b->delete($data->{_id});
is $b->get($data->{_id}), undef;

$b->add($data);

is_deeply $b->get_or_add($data->{_id}, {a=>{pony=>'wails'}}), $data;

is_deeply $b->to_hash, {$data->{_id}=>$data};

done_testing 26;

