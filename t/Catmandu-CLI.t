#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::CLI';
    use_ok $pkg;
}
require_ok $pkg;

# check -I / --lib_path
if ($^O ne 'MSWin32') { # /dev/null required
    # TODO Catmandu dies if testing with output to STDOUT
    my $res;
    $res = test_app('Catmandu::CLI' => [qw(
        -I t/lib convert Values --values 1;2;8 to JSON --file /dev/null
    )]);
    ok !$res->error;
    is $res->stderr, "";

    $res = test_app('Catmandu::CLI' => [qw(
        -I t/lib convert Values --values 1;2;8 to NotFound --file /dev/null
    )]);
    ok !$res->error;
    like $res->stderr, qr/Oops! Can't find the exporter 'NotFound'/;
}

done_testing;
