#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd::move';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw(move -v test to Hash) ]);

like $result->stderr, qr/moved 4 objects/, 'moved 4 objects' ;
is $result->error, undef, 'threw no exceptions' ;

done_testing 4;