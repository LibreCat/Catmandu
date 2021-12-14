#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Pluggable';
    use_ok $pkg;
}

{

    package Catmandu::Plugin::Frangle;
    use Moo::Role;

    sub frangle {
        "frangle";
    }

    package T::Pluggable;
    use Moo;
    with $pkg;
}

my $t = T::Pluggable->new;

can_ok $t, 'plugin_namespace';
can_ok $t, 'with_plugins';
is $t->plugin_namespace, 'Catmandu::Plugin';
dies_ok {$t->frangle} "original instance doesn't have plugin";

my $t_plugged = $t->with_plugins('Frangle');

ok $t_plugged, 'instance with plugin';
can_ok $t_plugged, 'frangle';

done_testing 7;

