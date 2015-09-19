#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny ':all';
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::add_to_exporter';
    use_ok $pkg;
}

my ($stdout, $stderr, $exit) = capture {
     my $fixer = Catmandu->fixer('add_to_exporter(.,JSON,array:1)');

     $fixer->fix({hello => 'world'});
};

is $stdout, qq|[{"hello":"world"}]\n| , 'fixed ok';

done_testing 2;