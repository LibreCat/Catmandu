#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Validator::Simple';
    use_ok $pkg;
}

require_ok $pkg;

my $v = Catmandu::Validator::Simple->new(validation_handler => sub { $_[0]->{field} eq '1' ? undef :
   'Not 1'});;
#isa_ok
can_ok $v, 'validate_hash';

throws_ok { $v->new(validation_handler => 1) } qr/Validation_handler should be a CODE reference/;

my $rec = {field => 1};

is $v->validate($rec), $rec;

is $v->validate({field => 3}), undef;

is_deeply $v->last_errors, ['Not 1'];

done_testing 7;