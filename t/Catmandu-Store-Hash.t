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

my $store = $pkg->new();
my $bag = $store->bag;
my @method = qw(to_array each take add add_many count slice first rest any many all tap map reduce);
can_ok $bag, $_ for @method;

$bag->add_many($data);
is $bag->count, 2, "Count bag size";
isnt $bag->count, 0, "Count bag size";

is_deeply $bag->first, {_id => '123', name=>'Patrick',age=>'39'}, "Data package ok.";
is_deeply $bag->rest->first, {_id => '321', name=>'Nicolas',age=>'34'}, "Data package ok.";

$bag->delete('123');
is_deeply $bag->first, {_id => '321', name=>'Nicolas',age=>'34'}, "Data package ok.";
is $bag->count, 1, "Count bag size";
$bag->delete_all;
is $bag->count, 0, "Count bag size";
isnt $bag->count, 1, "Count bag size";

$bag->add({ _id => '123' , foo => "bar"});

my $bag2 = $store->bag;
is $bag2->count , 1 , "Bags stay alive";

my $bag3 = $store->bag('foo');
ok ! $bag3->get('123') , "foo doesnt have 123";


$bag->delete_all;
for(1..100){
    $bag->add({ title => "title $_", author => "author $_" });
}

can_ok $bag, $_ for qw(search searcher delete_by_query translate_sru_sortkeys translate_cql_query);
is $bag->search( query => "title 1" )->total, 12, "search in store";
is $bag->search( )->total, 100, "search in store with empty query";
$bag->delete_by_query( query => "title 1" );
is $bag->search( query => "title 1" )->total, 0, "search in store";
is $bag->search( )->total, 88, "search in store";

$bag->delete_all();

for(1..100){
    my $title_key = int($_ / 10);
    $bag->add({
        title => "title $title_key",
        author => "author $_"
    });
}

{
    my $got = $bag->searcher( sort => "title asc,author desc" )->to_array();
    my $expected = [ sort {
        my $diff = $a->{title} cmp $b->{title};
        if( $diff == 0 ){
            $diff = $a->{author} cmp $b->{author};
            $diff = -$diff;
        }
        $diff;
    } @{ $bag->to_array } ];
    is_deeply $got,$expected, "multi key sort";
}

done_testing 37;

