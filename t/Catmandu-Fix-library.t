#!/usr/bin/env perl
use lib 't/lib';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::library';
    use_ok $pkg;
}

{
  is_deeply $pkg->new('T::Foo::Bar')->fix({}), {},"added an external fix method";
}

{
  my $fixer = Catmandu->fixer('library("T::Foo::Bar"); test(); if is_42(n) add_field(con,ok) end');

  ok $fixer , 'got a fixer';

  is_deeply $fixer->fix({n => '42'}) , { test => 'ok' , con => 'ok' , n => 42} , 'got the expected results';
}

done_testing 4;
