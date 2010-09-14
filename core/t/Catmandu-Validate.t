#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN { use_ok('Catmandu::Validate'); }
require_ok('Catmandu::Validate');

use Catmandu::Validate;

my $validator = Catmandu::Validate->new();

isa_ok($validator, 'Catmandu::Validate', 'isa Validator');

throws_ok { $validator->validate({}) } qr /requires a schema/ , 'caught requires schema';

$validator = Catmandu::Validate->new(schema => {});

lives_ok { my $ans = $validator->validate({}) } , 'expecting to live';
lives_ok { my $ans = $validator->validate(obj => {}) } , 'expecting to live';

lives_ok { Catmandu::Validate::validate(obj => {} , schema => {}) } , 'expecting to live';

my $obj = { foo => 'bar' , a => { deep => { tree => {} } } };

is_deeply($validator->validate($obj), $obj, 'test validate response');
is_deeply($validator->validate(obj =>$obj), $obj, 'test validate response');
is_deeply(Catmandu::Validate::validate(obj => $obj, schema => {}), $obj, 'test validate response');
