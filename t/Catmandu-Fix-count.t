#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::count';
    use_ok $pkg;
}

is_deeply $pkg->new('tags')->fix({tags => [qw(smelly stinky malodorous)]}), {tags => 3};
is_deeply $pkg->new('authors.*')->fix(
    {authors => [{firstname => "Mark", lastname => "Twain"}, {name => "Virgil"}]}),
    {authors => [2, 1]};
is_deeply $pkg->new('name')->fix({name => "Huckleberry Finn"}), {name => "Huckleberry Finn"};
is_deeply $pkg->new('name')->fix({name => undef}), {name => undef};

done_testing 5;
