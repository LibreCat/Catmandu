#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Store::Hash';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
   {_id => '123', name=>'Patrick',age=>'39'},
   {_id => '321', name=>'Nicolas',age=>'34'},
];

my $bag = $pkg->new()->bag;
my @method = qw(to_array each take add add_many count slice first rest any many all tap map reduce);
can_ok $bag, $_ for @method;

$bag->add_many($data);
is $bag->count, 2, "Count bag size";
isnt $bag->count, 0, "Count bag size";

is_deeply $bag->first, {_id => '123', name=>'Patrick',age=>'39'}, "Data package ok.";
is_deeply $bag->rest->first, {_id => '321', name=>'Nicolas',age=>'34'}, "Data package ok.";

done_testing 21;

