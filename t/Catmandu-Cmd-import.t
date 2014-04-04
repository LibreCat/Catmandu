#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester::CaptureExternal;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::import';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(import CSV -v --file t/planets.csv to Hash) ]);

like $result->stderr, qr/imported 4 objects/, 'imported 4 objects' ;
is $result->error, undef, 'threw no exceptions' ;

done_testing 4;