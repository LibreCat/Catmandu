#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::info';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result;

$result = test_app(qq|Catmandu::CLI| => [qw(info)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --exporters)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --importers)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --fixes)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --stores)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --validators)]);

is $result->error, undef, 'threw no exceptions';

$result = test_app(qq|Catmandu::CLI| => [qw(info --fixes to JSON)]);

is $result->error, undef, 'threw no exceptions';

done_testing;
