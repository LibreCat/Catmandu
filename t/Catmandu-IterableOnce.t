#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::IterableOnce';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::IterableOnce;
    use Catmandu::Sane;
    use Moo;
    with 'Catmandu::Iterable';
    with $pkg;

    sub generator {
        my ($self) = @_;
        my $data   = [1 .. 3];
        my $n      = 0;
        sub {
            return $data->[$n++] if $n < @$data;
            return;
        };
    }
}

my $iter = T::IterableOnce->new;

is_deeply $iter->to_array, [1, 2, 3], 'first iteration gives results';
is_deeply $iter->to_array, [],        'repeated iterations give no results';

done_testing;
