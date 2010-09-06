#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp;

my $filename = '/tmp/test.mock';

my $test = {
  name    => 'test123',
  num     => 3.1415926536 ,
  colors  => [qw(red green blue)] ,
  authors => [
        { name => "Albert" ,
          last_name => "Einstein",
          theory => [qw(relativity quantum heat)], } ,
        { name => "Paul" ,
          last_name => "Dirac",
          theory => [qw(quantum)] } ,
  ] ,
};

use Test::More tests => 10;
use Test::Exception;

BEGIN { use_ok('Catmandu::Store::Mock'); }
require_ok('Catmandu::Store::Mock');

use Catmandu::Store::Mock;

unlink $filename;

my $store = Catmandu::Store::Mock->connect(file=>$filename);

isa_ok($store,'Catmandu::Store::Mock','Catmandu::Store->connect');

ok(defined $store->save($test), 'save');

warn "stored object as " . $test->{_id};

my $obj = $store->load($test->{_id});

ok(defined $obj,'load');

is_deeply($obj,$test,'load equals memory');

ok($store->each == 1, 'list');

ok($store->each(sub { my $obj = shift; ok($obj->{name} eq 'test123')}) == 1, 'list');

ok($store->delete($obj));

unlink $filename;
