#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;
use Catmandu::CLI;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::oops';
    use_ok $pkg;
}

sub test_oops {
	my ($fix, $stderr, $msg) = @_;

    my $result = test_app(
        qq|Catmandu::CLI| => [qw(convert Null to Null --fix), $fix]);
    like $result->stderr, $stderr, $msg // $fix;
    $result;
}

ok !test_oops('oops()', qr/^Oops!/)->error, 'exit code';

test_oops('oops("WTF!")', qr/^WTF!/);

test_oops('oops("WTF!")', qr/^WTF!/);

test_oops('set_field(errors,42) oops()', qr/^42/, 'scalar errors');

test_oops('add_field(errors.message,42) oops()', qr/^42/, 'error object');

test_oops('add_field(errors.$append.message,42) oops()', qr/^42/, 'error objects');

test_oops('add_field(errors,42) oops("Sorry")', qr/^Sorry\n42/, 'prepend message');

test_oops('add_field(errors.$append,7) add_field(errors.$append,3) oops()',
	qr/^7\n3/, 'multiple errors');

done_testing;
