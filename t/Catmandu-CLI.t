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
    # FIXME: Catmandu dies if testing with output to STDOUT
    my $result = test_app( 'Catmandu::CLI' => [qw(
        -I /dev/null -I t/lib convert Values --values 1;2;8 to JSON -file /dev/null
    )] );
    ok !$result->error;
}

done_testing;

