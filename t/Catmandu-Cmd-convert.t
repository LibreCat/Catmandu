#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::convert';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

{
    my $result = test_app(qq|Catmandu::CLI| =>
            [qw(convert -v YAML --file t/catmandu.yml to JSON)]);

    my $perl = decode_json($result->stdout);

    ok $perl, 'got JSON';
    is $perl->[0]->{importer}{default}{package}, 'YAML', 'got data';
    is $result->error,                           undef, 'threw no exceptions';
}

{
    my $result = test_app(
        qq|Catmandu::CLI| => [
            'convert', '-v',       '--start=2',     '--total=1',
            'CSV',     '--file',   't/planets.csv', 'to',
            'CSV',     '--header', '0',             '--fields',
            'english,latin'
        ]
    );
    is $result->stdout, "Moon,Luna\n", 'start and limit';
}

{
    my $result = test_app(
        qq|Catmandu::CLI| => [
            'convert',   'CSV',
            '--file',    't/planets.csv',
            '--fix',     'copy_field(english,_id)',
            'to',        'CSV',
            '--header',  '0',
            '--fields',  'latin',
            '--id-file', 't/planet_ids.txt'
        ]
    );
    is $result->stdout, "Sol\nLuna\nTerra\n", 'id file';
}

done_testing;
