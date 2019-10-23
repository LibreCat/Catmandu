#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::disassoc';
    use_ok $pkg;
}

is_deeply $pkg->new('fields', 'pairs', 'key', 'val')
    ->fix({fields => {subject => 'Perl', year => 2009}}),
    {
    fields => {subject => 'Perl', year => 2009},
    pairs => [{key => 'subject', val => 'Perl'}, {key => 'year', val => 2009}]
    };

is_deeply $pkg->new('fields', 'my.deep.field', 'key', 'val')
    ->fix({fields => {subject => 'Perl', year => 2009}}),
    {
    fields => {subject => 'Perl', year => 2009},
    my     => {
        deep => {
            field => [
                {key => 'subject', val => 'Perl'},
                {key => 'year',    val => 2009}
            ]
        }
    }
    };

is_deeply $pkg->new('fields', '', 'key', 'val')
    ->fix({fields => {subject => 'Perl', year => 2009}}),
    {fields => {subject => 'Perl', year => 2009}}, "can't replace root";

done_testing;
