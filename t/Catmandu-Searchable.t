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
    package T::SearchableWithoutGenerator;
    use Moo;

    package T::Searchable;
    use Moo;
    with $pkg;

    sub search { die "not implemented" }
    sub searcher { die "not implemented" }
    sub delete_by_query { die "not implemented" }
    sub translate_cql_query { die "not implemented" }
    sub translate_sru_sortkeys { die "not implemented" }
}

throws_ok { Role::Tiny->apply_role_to_package('T::SearchableWithoutGenerator', $pkg) } qr/missing translate_sru_sortkeys, translate_cql_query, search, searcher, delete_by_query/;

my $iter = T::Searchable->new();

is $iter->default_default_limit , 10 ;
is $iter->default_maximum_limit , 1000;
is $iter->normalize_query("foo bar") , "foo bar";

done_testing 6;

