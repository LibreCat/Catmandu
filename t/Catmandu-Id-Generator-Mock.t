#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Id::Generator::Mock';
    use_ok $pkg;
}
require_ok $pkg;

{
    my $expected = [0..10];
    my $generated = [];
    my $id_generator = $pkg->new();
    isa_ok( $id_generator,"Catmandu::Id::Generator::Mock" );
    ok( $id_generator->does( "Catmandu::Id::Generator" ), "An object of class 'Catmandu::Id::Generator::Mock' does 'Catmandu::Id::Generator'" );
    for(@$expected){
        push @$generated,$id_generator->generate();
    }
    is_deeply $generated,$expected,"generated ids correct (no default 'start' value)";
}
{
    my $expected = [5..20];
    my $generated = [];
    my $id_generator = $pkg->new( start => $expected->[0] );
    isa_ok( $id_generator,"Catmandu::Id::Generator::Mock" );
    ok( $id_generator->does( "Catmandu::Id::Generator"), "An object of class 'Catmandu::Id::Generator::Mock' does 'Catmandu::Id::Generator'" );
    for(@$expected){
        push @$generated,$id_generator->generate();
    }
    is_deeply $generated,$expected,"generated ids correct (default 'start' value is '5')";
}

done_testing 8;
