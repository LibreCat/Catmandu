#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Cmd';
    use_ok $pkg;
}
require_ok $pkg;

use Catmandu::CLI;

my $result = test_app(qq|Catmandu::CLI| => [ qw() ]);

like $result->stdout , qr/Available commands:/, 'printed what we expected';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

$result = test_app('Catmandu::CLI' => [ qw(help) ]);

like $result->stdout , qr/Available commands:/, 'printed what we expected';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

$result = test_app('Catmandu::CLI' => [ qw(-h) ]);

like $result->stdout , qr/Available commands:/, 'printed what we expected';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

$result = test_app('Catmandu::CLI' => [ qw(version) ]);

like $result->stdout , qr/version $Catmandu::VERSION/, 'printed what we expected';
is $result->error, undef, 'threw no exceptions' ;
is $result->stderr, '', 'nothing sent to sderr' ;

done_testing 14;

