#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::config';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [qw(config to JSON)]);
my $perl   = decode_json($result->stdout);

ok $perl, 'got JSON';
is $perl->[0]->{importer}{default}{package}, 'YAML', 'got data';
is $result->error,                           undef,  'threw no exceptions';
is $result->stderr,                          '',     'nothing sent to sderr';

$result = test_app(
    qq|Catmandu::CLI| => [qw(config importer.default.package to JSON)]);

like $result->stdout, qr/"YAML"/, 'got data';
is $result->error,  undef, 'threw no exceptions';
is $result->stderr, '',    'nothing sent to sderr';

$result = test_app(
    qq|Catmandu::CLI| => [qw(config --fix add_field(foo:FOOBAR) to JSON)]);

like $result->stdout, qr/"FOOBAR"/, 'got data';
is $result->error,  undef, 'threw no exceptions';
is $result->stderr, '',    'nothing sent to sderr';

done_testing;
