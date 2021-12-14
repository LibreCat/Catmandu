#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::int';
    use_ok $pkg;
}

is_deeply $pkg->new('int')->fix({}), {};
is_deeply $pkg->new('int')->fix({int => ""}),              {int => 0};
is_deeply $pkg->new('int')->fix({int => "0"}),             {int => 0};
is_deeply $pkg->new('int')->fix({int => "+0"}),            {int => 0};
is_deeply $pkg->new('int')->fix({int => "-0"}),            {int => 0};
is_deeply $pkg->new('int')->fix({int => "abc-123"}),       {int => -123};
is_deeply $pkg->new('int')->fix({int => "abc+123.00005"}), {int => 123};
is_deeply $pkg->new('int')->fix({int => "abc+123.99999"}), {int => 123};
is_deeply $pkg->new('int')->fix({int => []}),              {int => 0};
is_deeply $pkg->new('int')->fix({int => [1, 2, 3]}),               {int => 3};
is_deeply $pkg->new('int')->fix({int => [1, {2 => 3}]}),           {int => 2};
is_deeply $pkg->new('int')->fix({int => {}}),                      {int => 0};
is_deeply $pkg->new('int')->fix({int => {3 => 4, 1 => 2}}),        {int => 2};
is_deeply $pkg->new('int')->fix({int => {3 => {4 => 5}, 1 => 2}}), {int => 2};

done_testing;
