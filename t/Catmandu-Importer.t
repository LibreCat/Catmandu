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
    $pkg = 'Catmandu::Importer';
    use_ok $pkg;
}
require_ok $pkg;

{
    package T::Importer;
    use Moo;
    with $pkg;

    sub generator { sub {} }
}

my $i = T::Importer->new;
ok $i->does('Catmandu::Iterable');

done_testing 3;

