#!/usr/bin/env perl

package T::MyBlessed;

use Moo;
use overload '""' => 'stringify';

sub stringify { ":-P yuck" }

package main;

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::vacuum';
    use_ok $pkg;
}

my $res = $pkg->new()->fix({
    	arrays => [] ,
    	hashes => {} ,
    	strings => '' ,
    	nested_strings => { nested => '' } ,
    	nested_arrays  => { arrays => [] } ,
    	nested_hashes  => { hashes => {} } ,
    	keep_me => { arrays => [] , hashes => { foo => [] } , me => 1} ,
    	keep_me_2 => [ [] , [T::MyBlessed->new] ],
    });

is_deeply
	$res,
    { keep_me => {me => 1} , keep_me_2 => [undef,[":-P yuck"]]},
    "data is vacuumed";

done_testing 2;
