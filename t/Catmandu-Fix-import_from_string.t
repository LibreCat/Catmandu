#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::import_from_string';
    use_ok $pkg;
}

is_deeply $pkg->new('record','JSON')->fix({ record => qq({"name":"Nicolas"}\n) }),
    { record => [{ "name" => "Nicolas" }] },"convert single JSON object to array of hashes";

is_deeply $pkg->new('record','JSON')->fix({ record => qq([{"name":"Nicolas"}]\n) }),
    { record => [{ "name" => "Nicolas" }] },"convert JSON array to array of hashes";

is_deeply $pkg->new('record','YAML')->fix({ record => qq(---\nname: Nicolas\n...\n) }),
    { record => [{ "name" => "Nicolas" }] },"convert single YAML object to array of hashes";

is_deeply $pkg->new('record','YAML')->fix({ record => qq(---\nname: Nicolas\n...\n---\nname: Patrick\n...\n) }),
    { record => [{ "name" => "Nicolas" },{ "name" => "Patrick" }] }, "convert YAML array to array of hashes";

is_deeply $pkg->new('record','CSV')->fix({ record => qq(name\nNicolas\n) }),
    { record => [{ "name" => "Nicolas" }] },"convert single CSV line to array of hashes";

is_deeply $pkg->new('record','CSV', sep_char => ';')->fix({ record => qq(first_name;name\nNicolas;Franck\nPatrick;Hochstenbach\n) }),
    { record => [{ "first_name" => "Nicolas",name => "Franck" },{ "first_name" => "Patrick",name => "Hochstenbach" }] },"convert CSV array to array of hashes";

done_testing;
