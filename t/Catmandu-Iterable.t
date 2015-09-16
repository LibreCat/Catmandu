#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Iterable';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::IterableWithoutGenerator;
    use Moo;

    package T::Iterable;
    use Moo;
    with $pkg;

    has data => (is => 'rw');

    sub generator {
        my ($self) = @_;
        my $data = $self->data;
        my $n = 0;
        sub {
            return $data->[$n++] if $n < @$data;
            return;
        };
    }

    package T::CountArgs;
    use Moo;

    sub count_args { @_ - 1 }

}

throws_ok { Role::Tiny->apply_role_to_package('T::IterableWithoutGenerator', $pkg) } qr/missing generator/;

my $iter = T::Iterable->new(data => [1,2,3]);

is_deeply $iter->to_array, [1,2,3];

is $iter->count, 3;

{
    my $d = [];
    my $n = $iter->each(sub { push @$d, $_[0] });
    is_deeply $d, $iter->to_array;
    is $n, 3;
}

is_deeply $iter->tap(sub { $_[0] })->to_array, $iter->to_array;

is $iter->any(sub { $_[0] < 3 }), 1;
is $iter->any(sub { $_[0] > 3 }), 0;

is $iter->many(sub { $_[0] < 3 }), 1;
is $iter->many(sub { $_[0] < 2 }), 0;

is $iter->all(sub { $_[0] > 0 }), 1;
is $iter->all(sub { $_[0] > 1 }), 0;

is_deeply $iter->map(sub { $_[0] + 1 })->to_array, [2,3,4];

is $iter->reduce(sub { my ($memo, $num) = @_; $memo + $num; }), 6;
is $iter->reduce(1, sub { my ($memo, $num) = @_; $memo + $num; }), 7;
is_deeply $iter->reduce({}, sub { my ($memo, $num) = @_; $memo->{$num} = $num + 1; $memo; }), {1=>2,2=>3,3=>4};

is $iter->first, 1;

is_deeply $iter->rest->to_array, [2,3];

is_deeply $iter->take(1)->to_array, [1];
is_deeply $iter->take(2)->to_array, [1,2];

is $iter->detect(sub { $_[0] == 3 }), 3;
is $iter->detect(sub { $_[0] == 4 }), undef;

is_deeply $iter->select(sub { $_[0] < 1 })->to_array, [];
is_deeply $iter->select(sub { $_[0] > 1 })->to_array, [2,3];
is_deeply $iter->grep  (sub { $_[0] < 1 })->to_array, [];
is_deeply $iter->grep  (sub { $_[0] > 1 })->to_array, [2,3];

is_deeply $iter->reject(sub { $_[0] < 2 })->to_array, [2,3];
is_deeply $iter->reject(sub { $_[0] > 0 })->to_array, [];

is $iter->detect(qr'[12]'), 1;
is_deeply $iter->select(qr'[12]')->to_array, [1,2];
is_deeply $iter->grep  (qr'[12]')->to_array, [1,2];
is_deeply $iter->reject(qr'[12]')->to_array, [3];

$iter->data([{num=>1},{num=>2},{num=>3}]);

is_deeply $iter->detect(num => qr'[12]'), {num=>1};
is_deeply $iter->select(num => qr'[12]')->to_array, [{num=>1},{num=>2}];
is_deeply $iter->grep  (num => qr'[12]')->to_array, [{num=>1},{num=>2}];
is_deeply $iter->reject(num => qr'[12]')->to_array, [{num=>3}];

is_deeply $iter->pluck('num')->to_array, $iter->map(sub { $_[0]->{num} })->to_array;

$iter->data([T::CountArgs->new]);
is_deeply $iter->invoke('count_args')->to_array, [0];
is_deeply $iter->invoke('count_args','arg1','arg2')->to_array, [2];

$iter->data([{a=>{b =>'c'}},'d',{c=>{b=>'a'}}]);
is $iter->includes({c => {a => 'b'}}), 0;
is $iter->contains({c => {a => 'b'}}), 0;
is $iter->includes({c => {b => 'a'}}), 1;
is $iter->contains({c => {b => 'a'}}), 1;

$iter->data([1 .. 10]);
is_deeply $iter->group(3)->invoke('to_array')->to_array,
    [[1,2,3],[4,5,6],[7,8,9],[10]];
is_deeply $iter->group(1)->invoke('to_array')->to_array,
    [[1],[2],[3],[4],[5],[6],[7],[8],[9],[10]];
$iter->data([]);
is_deeply $iter->group(3)->invoke('to_array')->to_array,
    [];

$iter->data([1,2,3]);
is_deeply $iter->interleave->to_array, $iter->data;
is_deeply $iter->interleave(
        T::Iterable->new(data => [4,5,6]),
        T::Iterable->new(data => [7,8,9]))->to_array,
    [1,4,7,2,5,8,3,6,9];
is_deeply $iter->interleave(
        T::Iterable->new(data => [4,5]))->to_array,
    [1,4,2,5,3];
$iter->data([1,2]);
is_deeply $iter->interleave(
        T::Iterable->new(data => [4,5,6]))->to_array,
    [1,4,2,5,6];

$iter->data([2,1,'10foo','foo10',-1,-2]);
is $iter->min, -2;
is $iter->max,  2;

$iter->data([]);
is $iter->min, undef;
is $iter->max, undef;

$iter->data(['foo']);
is $iter->min, undef;
is $iter->max, undef;

$iter->data(['foo', 'oof']);
is $iter->min, undef;
is $iter->max, undef;

$iter->data([{n=>10},{n=>9},{n=>1}]);
is $iter->min(sub {shift->{n}}), 1;
is $iter->max(sub {shift->{n}}), 10;

$iter->data([{n=>10},{n=>9},{n=>1}]);
is_deeply $iter->stop_if(sub { shift->{n} == 9 })->to_array,
   [{n=>10}];
is_deeply $iter->stop_if(sub { shift->{n} == 1 })->to_array,
   [{n=>10},{n=>9}];

is_deeply $iter->sorted('n')->to_array, [{n=>1},{n=>10},{n=>9}];

$iter->data([3,21,1]);

is_deeply $iter->sorted->to_array, [1,21,3]; 
is_deeply $iter->sorted(sub { $_[1] <=> $_[0] })->to_array, [21,3,1];

# external iteration
{
    $iter->data([{n=>1},{n=>2},{n=>3}]);
    my $iter_data = [];
    while (my $data = $iter->next) {
        push @$iter_data, $data;
    }
    is_deeply $iter->data, $iter_data;
    is $iter->next, undef;
    $iter->rewind;
    is_deeply $iter->next, {n=>1};
}

done_testing;
