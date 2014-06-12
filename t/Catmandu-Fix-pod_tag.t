#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {    
    $pkg = 'Catmandu::Fix::pod_tag';
    use_ok $pkg;
}

my $object = $pkg->new('syntax','SYNTAX')->fix({ syntax => $pkg });
ok( $object->{syntax} ne $pkg );

done_testing 2;
