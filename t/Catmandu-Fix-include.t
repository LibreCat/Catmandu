#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::include';
    use_ok $pkg;
}

my $object = {};
my $intended_object = {
    name => "Franck",
    first_name => "Nicolas",
    working_place => "University Library of Ghent"
};
my $fix_file = "t/fix-level-1.txt";

is_deeply(
    $pkg->new($fix_file)->fix($object),
    $intended_object,
    "include fix at multiple levels"
);

done_testing 2;
