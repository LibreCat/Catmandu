#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::compile';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => ['compile','nothing()']);

ok $result->stdout;

is $result->error, undef, 'threw no exceptions';

done_testing 4;
