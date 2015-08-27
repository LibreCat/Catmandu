#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Util;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Store::Hash';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $bag;

    lives_ok(sub{

        $bag = $pkg->new(bags => { data => { id_generator => "Mock" } });

    },"create bag with id generator Mock");

    my $ids = [0..10];
    my $objects = [
    map {
        +{
            title => "test"
        };
    }
    @$ids ];

    lives_ok(sub{
        $bag->add_many($objects);
    },"add objects to bag");

    {
        my $i = 0;
        $_->{_id} = $i++ for(@$objects);
    }

    is_deeply $bag->to_array, $objects,
        "created objects contain expected identifiers";
}


done_testing;

