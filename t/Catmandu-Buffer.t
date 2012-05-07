#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Buffer';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Buffer;
    use Moo;
    with $pkg;
}

my $b = T::Buffer->new;

can_ok $b, 'buffer_size';
can_ok $b, 'buffer';
can_ok $b, 'default_buffer_size';
can_ok $b, 'buffer_used';
can_ok $b, 'buffer_is_full';
can_ok $b, 'buffer_add';
can_ok $b, 'clear_buffer';

is $b->buffer_size, $b->default_buffer_size;

$b = T::Buffer->new(buffer_size => 5);
is $b->buffer_size, 5;
is $b->buffer_used, 0;

$b->buffer_add(1,2,3);
is $b->buffer_used, 3;
is_deeply $b->buffer, [1,2,3];
is $b->buffer_is_full, 0;

$b->buffer_add(4,5,6);
is $b->buffer_used, 6;
is_deeply $b->buffer, [1,2,3,4,5,6];
is $b->buffer_is_full, 1;

$b->clear_buffer;
is $b->buffer_used, 0;
is_deeply $b->buffer, [];
is $b->buffer_is_full, 0;

done_testing 21;

