#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('Catmandu::Indexer::Converter'); }
require_ok('Catmandu::Indexer::Converter');

use Catmandu::Indexer::Converter;

my $converter = Catmandu::Indexer::Converter->new();

ok($converter, 'new');

my $ref = {
          field1 => 'XYZ' ,
          field2 => [qw(A B C D)] ,
          field3 => { f1 => 'I' , f2 => 'B' , f3 => 'M' } ,
          field4 => [ 
                      { f1 => 0 , f2 => 0 , f3 => 1 } ,
                      { f1 => 0 , f2 => 1 , f3 => 0 } ,
                      { f1 => 1 , f2 => 0 , f3 => 0 } ,
                    ]
         };

my $exp = {
          field1 => 'XYZ' ,
          field2 => "A B C D" ,
          field3 => 'I B M',
          field4 => "0 0 1 0 1 0 1 0 0"
          };

is_deeply($converter->convert($ref), $exp, 'convert');


my $converter2 = Catmandu::Indexer::Converter->new(mapping => { 'field2' => 'fa' , 'field4' => 'fb' });

ok($converter2, 'new');

my $exp2 = {
          fa => "A B C D" ,
          fb => "0 0 1 0 1 0 1 0 0"
            };

is_deeply($converter2->convert($ref), $exp2, 'convert with mapping');
