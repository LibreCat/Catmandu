#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Cmd::touch';
    use_ok $pkg;
}

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [qw(touch --field date)]);

is $result->error, undef, 'threw no exceptions';

done_testing;
