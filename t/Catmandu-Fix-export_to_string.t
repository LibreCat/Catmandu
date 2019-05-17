#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::export_to_string';
    use_ok $pkg;
}

is_deeply $pkg->new('record', 'JSON')->fix({record => {"name" => "Nicolas"}}),
    {record => qq([{"name":"Nicolas"}]\n)}, "convert hash to JSON";

is_deeply $pkg->new('record', 'JSON')
    ->fix({record => [{"name" => "Nicolas"}]}),
    {record => qq([{"name":"Nicolas"}]\n)}, "convert array of hashes to JSON";

is_deeply $pkg->new('record', 'YAML')->fix({record => {"name" => "Nicolas"}}),
    {record => qq(---\nname: Nicolas\n...\n)}, "convert hash to YAML";

is_deeply $pkg->new('record', 'YAML')
    ->fix({record => [{"name" => "Nicolas"}, {"name" => "Patrick"}]}),
    {record => qq(---\nname: Nicolas\n...\n---\nname: Patrick\n...\n)},
    "convert array of hashes to YAML";

is_deeply $pkg->new('record', 'CSV')->fix({record => {"name" => "Nicolas"}}),
    {record => qq(name\nNicolas\n)}, "convert hash to CSV";

is_deeply $pkg->new(
    'record', 'CSV',
    'sep_char' => ';',
    fields     => ["first_name", "name"]
)->fix(
    {
        record => [
            {"first_name" => "Nicolas", name => "Franck"},
            {"first_name" => "Patrick", name => "Hochstenbach"}
        ]
    }
    ),
    {record => qq(first_name;name\nNicolas;Franck\nPatrick;Hochstenbach\n)},
    "convert array of hashes to CSV";

done_testing;
