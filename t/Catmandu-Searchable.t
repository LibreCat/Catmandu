#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Searchable';
    use_ok $pkg;
}
require_ok $pkg;

{

    package T::EmptySearchable;
    use Moo;

    package T::Searchable;
    use Moo;
    with $pkg;

    sub search          {die "not implemented"}
    sub searcher        {die "not implemented"}
    sub delete_by_query {die "not implemented"}
}

throws_ok {
    Role::Tiny->apply_role_to_package('T::EmptySearchable', $pkg)
}
qr/missing search, searcher, delete_by_query/;

my $s = T::Searchable->new;

is $s->default_limit,              10;
is $s->maximum_limit,              1000;
is $s->normalize_query("foo bar"), "foo bar";

done_testing;
