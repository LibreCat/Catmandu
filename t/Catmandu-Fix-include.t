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

my $object          = {};
my $intended_object = {
    name          => "Franck",
    first_name    => "Nicolas",
    working_place => "University Library of Ghent",
    hobbies       => ['cooking', 'art', 'hiking']
};
my $fix_file = "fix-level-1.fix";

is_deeply($pkg->new($fix_file)->fix($object),
    $intended_object, "include fix at multiple levels");

done_testing 2;
