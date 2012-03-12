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
    $pkg = 'Catmandu::Iterable';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Iterable;

    use Moo;

    with 'Catmandu::Iterable';

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
}

my $iter = T::Iterable->new(data => [1,2,3]);

is_deeply $iter->to_array, [1,2,3];
is $iter->all(sub { $_[0] > 0 }), 1;
is $iter->all(sub { $_[0] > 1 }), 0;

is $iter->any(sub { $_[0] < 3 }), 1;
is $iter->any(sub { $_[0] > 3 }), 0;

is $iter->many(sub { $_[0] < 3 }), 1;
is $iter->many(sub { $_[0] < 2 }), 0;

is_deeply $iter->map(sub { $_[0] + 1 })->to_array, [2,3,4];

is $iter->detect(sub { $_[0] == 3 }), 3;
is $iter->detect(sub { $_[0] == 4 }), undef;

is_deeply $iter->select(sub { $_[0] < 1 })->to_array, [];
is_deeply $iter->select(sub { $_[0] > 1 })->to_array, [2,3];

is_deeply $iter->reject(sub { $_[0] < 2 })->to_array, [2,3];
is_deeply $iter->reject(sub { $_[0] > 0 })->to_array, [];

is $iter->reduce(sub { my ($memo, $num) = @_; $memo + $num; }), 6;
is $iter->reduce(1, sub { my ($memo, $num) = @_; $memo + $num; }), 7;
is_deeply $iter->reduce({}, sub { my ($memo, $num) = @_; $memo->{$num} = $num + 1; $memo; }), {1=>2,2=>3,3=>4};

is $iter->first, 1;

is_deeply $iter->take(1)->to_array, [1];
is_deeply $iter->take(2)->to_array, [1,2];

$iter->data([{num=>1},{num=>2},{num=>3}]);
is_deeply $iter->pluck('num')->to_array, $iter->map(sub { $_[0]->{num} })->to_array;

done_testing 23;

