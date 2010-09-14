#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use File::Temp;

BEGIN { use_ok 'Catmandu::Store::Mock'; }
require_ok 'Catmandu::Store::Mock';

my $path = '/tmp/test.store';
my $test = {
    name    => 'test',
    num     => 3.1415926536 ,
    colors  => [qw(red green blue)],
    authors => [
        { name => "Albert" ,
          last_name => "Einstein",
          theory => [qw(relativity quantum heat)] },
        { name => "Paul" ,
          last_name => "Dirac",
          theory => [qw(quantum)] },
    ],
};

unlink $path;

my $store = Catmandu::Store::Mock->new(file => $path);

isa_ok $store,'Catmandu::Store::Mock','isa store';

ok(defined $store->save($test), 'save');

my $obj = $store->load($test->{_id});

ok(defined $obj, 'load');

is_deeply $obj, $test,'test deeply obj';

my $count = $store->each(sub { my $obj = shift; ok($obj->{name} eq 'test', 'yields obj')});

is $count, 1, 'counting 1 object';

ok $store->delete($obj);

unlink $path;

