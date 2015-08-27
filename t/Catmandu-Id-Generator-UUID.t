#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Id::Generator::UUID';
    use_ok $pkg;
}
require_ok $pkg;

my $id_generator = $pkg->new();
isa_ok( $id_generator,"Catmandu::Id::Generator::UUID" );
ok( $id_generator->does( "Catmandu::Id::Generator" ), "An object of class 'Catmandu::Id::Generator::UUID' does 'Catmandu::Id::Generator'" );

done_testing 4;
